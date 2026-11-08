#include "table_json.h"
#include <fstream>
#include <sstream>
#include <filesystem>
#include <iostream>
#include <cctype>
#include <cstdlib>
#include <string>
#include <vector>
#include <utility>

struct JsonValue {
    enum class Type { Null, Bool, Number, String, Array, Object };
    Type type = Type::Null;
    bool bool_value = false;
    double number_value = 0.0;
    bool number_is_integer = false;
    long long integer_value = 0;
    std::string string_value;
    std::vector<JsonValue> array_value;
    std::vector<std::pair<std::string, JsonValue>> object_value;

    const JsonValue* find(const std::string& key) const {
        for (const auto& entry : object_value) {
            if (entry.first == key) return &entry.second;
        }
        return nullptr;
    }
};

namespace {
    class JsonParser {
    public:
        explicit JsonParser(const std::string& text) : text_(text) {}
        bool parse(JsonValue& out, std::string& err) {
            if (text_.size() >= 3 && static_cast<unsigned char>(text_[0]) == 0xEF && static_cast<unsigned char>(text_[1]) == 0xBB && static_cast<unsigned char>(text_[2]) == 0xBF) position_ = 3;
            skip_ws(); if (!parse_val(out, 0)) { err = make_err(); return false; }
            skip_ws(); if (position_ != text_.size()) { err = make_err() + " (extra content)"; return false; }
            return true;
        }
    private:
        void skip_ws() { while (position_ < text_.size() && isspace(static_cast<unsigned char>(text_[position_]))) ++position_; }
        bool at_end() const { return position_ >= text_.size(); }
        bool parse_val(JsonValue& out, int d) {
            if (d > 64 || at_end()) { error_ = "depth exceeded or EOF"; return false; }
            switch (text_[position_]) {
                case '{': return parse_obj(out, d);
                case '[': return parse_arr(out, d);
                case '"': out.type = JsonValue::Type::String; return parse_str(out.string_value);
                case 't': case 'f': return parse_bool(out);
                case 'n': return parse_null(out);
                default: return parse_num(out);
            }
        }
        bool parse_obj(JsonValue& out, int d) {
            out.type = JsonValue::Type::Object; ++position_; skip_ws();
            if (!at_end() && text_[position_] == '}') { ++position_; return true; }
            while (true) {
                skip_ws(); if (at_end() || text_[position_] != '"') { error_ = "expected key string"; return false; }
                std::string key; if (!parse_str(key)) return false;
                skip_ws(); if (at_end() || text_[position_] != ':') { error_ = "expected colon"; return false; }
                ++position_; skip_ws();
                JsonValue val; if (!parse_val(val, d + 1)) return false;
                out.object_value.push_back({key, val});
                skip_ws();
                if (!at_end() && text_[position_] == ',') { ++position_; continue; }
                if (!at_end() && text_[position_] == '}') { ++position_; return true; }
                error_ = "expected comma or brace"; return false;
            }
        }
        bool parse_arr(JsonValue& out, int d) {
            out.type = JsonValue::Type::Array; ++position_; skip_ws();
            if (!at_end() && text_[position_] == ']') { ++position_; return true; }
            while (true) {
                JsonValue val; if (!parse_val(val, d + 1)) return false;
                out.array_value.push_back(val);
                skip_ws();
                if (!at_end() && text_[position_] == ',') { ++position_; continue; }
                if (!at_end() && text_[position_] == ']') { ++position_; return true; }
                error_ = "expected comma or bracket"; return false;
            }
        }
        bool parse_str(std::string& out) {
            ++position_;
            while (!at_end()) {
                char c = text_[position_];
                if (c == '"') { ++position_; return true; }
                if (c == '\\') {
                    ++position_; if (at_end()) return false;
                    char esc = text_[position_++];
                    if (esc == '"') out.push_back('"'); else if (esc == '\\') out.push_back('\\'); else if (esc == 'n') out.push_back('\n'); else if (esc == 't') out.push_back('\t'); else if (esc == 'r') out.push_back('\r'); else out.push_back(esc);
                    continue;
                }
                out.push_back(c); ++position_;
            }
            error_ = "unterminated string"; return false;
        }
        bool parse_bool(JsonValue& out) {
            if (text_.compare(position_, 4, "true") == 0) { position_ += 4; out.type = JsonValue::Type::Bool; out.bool_value = true; return true; }
            if (text_.compare(position_, 5, "false") == 0) { position_ += 5; out.type = JsonValue::Type::Bool; out.bool_value = false; return true; }
            error_ = "invalid bool"; return false;
        }
        bool parse_null(JsonValue& out) {
            if (text_.compare(position_, 4, "null") == 0) { position_ += 4; out.type = JsonValue::Type::Null; return true; }
            error_ = "invalid null"; return false;
        }
        bool parse_num(JsonValue& out) {
            size_t start = position_; if (text_[position_] == '-') ++position_;
            while (!at_end() && isdigit(static_cast<unsigned char>(text_[position_]))) ++position_;
            bool is_int = true;
            if (!at_end() && text_[position_] == '.') { is_int = false; ++position_; while (!at_end() && isdigit(static_cast<unsigned char>(text_[position_]))) ++position_; }
            std::string token = text_.substr(start, position_ - start);
            out.type = JsonValue::Type::Number; out.number_is_integer = is_int;
            // 安全替换：不使用可能抛异常的 std::stoll / std::stod
            if (is_int) { out.integer_value = std::strtoll(token.c_str(), nullptr, 10); out.number_value = static_cast<double>(out.integer_value); }
            else { out.number_value = std::strtod(token.c_str(), nullptr); }
            return true;
        }
        std::string make_err() const { return "JSON Error: " + error_ + " at pos " + std::to_string(position_); }
        const std::string& text_; size_t position_ = 0; std::string error_;
    };

    void serialize(const JsonValue& val, std::ostringstream& oss, int indent = 0, bool compact = false) {
        std::string pad(indent * 2, ' ');
        std::string pad_in((indent + 1) * 2, ' ');
        
        switch (val.type) {
            case JsonValue::Type::Null: oss << "null"; break;
            case JsonValue::Type::Bool: oss << (val.bool_value ? "true" : "false"); break;
            case JsonValue::Type::Number: if (val.number_is_integer) oss << val.integer_value; else oss << val.number_value; break;
            case JsonValue::Type::String: oss << "\"" << val.string_value << "\""; break;
            
            case JsonValue::Type::Array:
                if (val.array_value.empty()) { oss << "[]"; break; }
                if (compact) {
                    oss << "[";
                    for (size_t i = 0; i < val.array_value.size(); ++i) {
                        serialize(val.array_value[i], oss, indent + 1, true);
                        if (i < val.array_value.size() - 1) oss << ", ";
                    }
                    oss << "]";
                } else {
                    oss << "[\n";
                    for (size_t i = 0; i < val.array_value.size(); ++i) {
                        oss << pad_in;
                        serialize(val.array_value[i], oss, indent + 1, true); 
                        if (i < val.array_value.size() - 1) oss << ",";
                        oss << "\n";
                    }
                    oss << pad << "]";
                }
                break;
                
            case JsonValue::Type::Object:
                if (val.object_value.empty()) { oss << "{}"; break; }
                if (compact) {
                    oss << "{ ";
                    for (size_t i = 0; i < val.object_value.size(); ++i) {
                        oss << "\"" << val.object_value[i].first << "\": ";
                        serialize(val.object_value[i].second, oss, indent, true); 
                        if (i < val.object_value.size() - 1) oss << ", ";
                    }
                    oss << " }";
                } else {
                    oss << "{\n";
                    for (size_t i = 0; i < val.object_value.size(); ++i) {
                        oss << pad_in << "\"" << val.object_value[i].first << "\": ";
                        
                        bool child_compact = true;
                        if (indent == 0 && (val.object_value[i].first == "headers" || val.object_value[i].first == "rows")) {
                            child_compact = false;
                        }
                        if (indent >= 1) {
                            child_compact = true;
                        }

                        serialize(val.object_value[i].second, oss, indent + 1, child_compact);
                        
                        if (i < val.object_value.size() - 1) oss << ",";
                        oss << "\n";
                    }
                    oss << pad << "}";
                }
                break;
        }
    }

    DataType str_to_type(const std::string& s) {
        if (s == "int") return DataType::Int;
        if (s == "bool") return DataType::Bool;
        if (s == "float") return DataType::Float;
        return DataType::String;
    }
    std::string type_to_str(DataType t) {
        if (t == DataType::Int) return "int";
        if (t == DataType::Bool) return "bool";
        if (t == DataType::Float) return "float";
        return "string";
    }
}

bool load_table_from_json(TableManager2D& table, const std::string& filepath, std::string* error_message) {
    std::ifstream in(std::filesystem::u8path(filepath), std::ios::binary);
    if (!in) { if (error_message) *error_message = "Cannot open file: " + filepath; return false; }
    std::string text((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
    JsonValue root; std::string err;
    JsonParser parser(text);
    if (!parser.parse(root, err)) { if (error_message) *error_message = err; return false; }

    table = TableManager2D();
    if (const JsonValue* tn = root.find("table_name")) table.table_name = tn->string_value;

    if (const JsonValue* heads = root.find("headers")) {
        for (const auto& h : heads->array_value) {
            ColumnDef def;
            if (const JsonValue* n = h.find("name")) def.name = n->string_value;
            if (const JsonValue* t = h.find("type")) def.type = str_to_type(t->string_value);
            if (const JsonValue* d = h.find("default")) {
                if (d->type == JsonValue::Type::String) def.default_value = d->string_value;
                else if (d->type == JsonValue::Type::Number) def.default_value = d->number_is_integer ? std::to_string(d->integer_value) : std::to_string(d->number_value);
                else if (d->type == JsonValue::Type::Bool) def.default_value = d->bool_value ? "true" : "false";
            }
            table.headers.push_back(def);
        }
    }

    if (const JsonValue* rws = root.find("rows")) {
        for (const auto& r : rws->object_value) {
            std::vector<std::string> row_data;
            for (const auto& cell : r.second.array_value) {
                if (cell.type == JsonValue::Type::String) row_data.push_back(cell.string_value);
                else if (cell.type == JsonValue::Type::Number) row_data.push_back(cell.number_is_integer ? std::to_string(cell.integer_value) : std::to_string(cell.number_value));
                else if (cell.type == JsonValue::Type::Bool) row_data.push_back(cell.bool_value ? "true" : "false");
            }
            table.rows[r.first] = row_data;
            table.row_names.push_back(r.first);
        }
    }

    table.build_index();
    return true;
}

bool save_table_to_json(const TableManager2D& table, const std::string& filepath) {
    JsonValue root; root.type = JsonValue::Type::Object;

    JsonValue tn; tn.type = JsonValue::Type::String; tn.string_value = table.table_name;
    root.object_value.push_back({"table_name", tn});

    JsonValue heads; heads.type = JsonValue::Type::Array;
    for (const auto& h : table.headers) {
        JsonValue head_obj; head_obj.type = JsonValue::Type::Object;
        JsonValue n; n.type = JsonValue::Type::String; n.string_value = h.name; head_obj.object_value.push_back({"name", n});
        JsonValue t; t.type = JsonValue::Type::String; t.string_value = type_to_str(h.type); head_obj.object_value.push_back({"type", t});
        
        JsonValue d;
        // 安全替换：不使用 try-catch 和 stoll/stod
        if (h.type == DataType::Int) { d.type = JsonValue::Type::Number; d.number_is_integer = true; d.integer_value = std::strtoll(h.default_value.c_str(), nullptr, 10); }
        else if (h.type == DataType::Bool) { d.type = JsonValue::Type::Bool; d.bool_value = (h.default_value == "true"); }
        else if (h.type == DataType::Float) { d.type = JsonValue::Type::Number; d.number_value = std::strtod(h.default_value.c_str(), nullptr); }
        else { d.type = JsonValue::Type::String; d.string_value = h.default_value; }
        head_obj.object_value.push_back({"default", d});
        
        heads.array_value.push_back(head_obj);
    }
    root.object_value.push_back({"headers", heads});

    JsonValue rws; rws.type = JsonValue::Type::Object;
    for (const auto& rn : table.row_names) {
        auto it = table.rows.find(rn);
        if (it == table.rows.end()) continue;
        
        JsonValue arr; arr.type = JsonValue::Type::Array;
        for (size_t i = 0; i < it->second.size(); ++i) {
            const std::string& val_str = it->second[i];
            JsonValue cell;
            DataType col_type = (i < table.headers.size()) ? table.headers[i].type : DataType::String;
            // 安全替换
            if (col_type == DataType::Int) { cell.type = JsonValue::Type::Number; cell.number_is_integer = true; cell.integer_value = std::strtoll(val_str.c_str(), nullptr, 10); }
            else if (col_type == DataType::Bool) { cell.type = JsonValue::Type::Bool; cell.bool_value = (val_str == "true"); }
            else if (col_type == DataType::Float) { cell.type = JsonValue::Type::Number; cell.number_value = std::strtod(val_str.c_str(), nullptr); }
            else { cell.type = JsonValue::Type::String; cell.string_value = val_str; }
            arr.array_value.push_back(cell);
        }
        rws.object_value.push_back({rn, arr});
    }
    root.object_value.push_back({"rows", rws});

    std::ofstream out(std::filesystem::u8path(filepath), std::ios::binary | std::ios::trunc);
    if (!out) return false;
    std::ostringstream oss;
    serialize(root, oss, 0);
    out << oss.str();
    return true;
}

bool add_column_to_json(const std::string& filepath, const std::string& col_name, const std::string& type_str, const std::string& default_val) {
    TableManager2D table;
    if (!load_table_from_json(table, filepath)) {
        table.table_name = "NewTable";
    }
    table.add_column_in_memory(col_name, str_to_type(type_str), default_val);
    return save_table_to_json(table, filepath);
}

bool add_row_to_json(const std::string& filepath, const std::string& row_name, const std::vector<std::string>& data) {
    TableManager2D table;
    if (!load_table_from_json(table, filepath)) return false;
    table.add_row_in_memory(row_name, data);
    return save_table_to_json(table, filepath);
}