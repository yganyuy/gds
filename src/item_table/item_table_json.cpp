#include "item_table.h"

#include <cctype>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iterator>
#include <string>
#include <utility>
#include <vector>
#include <sstream>
#include <filesystem> // 关键：用于解决中文路径写入

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
        bool parse(JsonValue& out_value, std::string& error) {
            if (text_.size() >= 3 && static_cast<unsigned char>(text_[0]) == 0xEF &&
                static_cast<unsigned char>(text_[1]) == 0xBB && static_cast<unsigned char>(text_[2]) == 0xBF) {
                position_ = 3;
            }
            skip_whitespace();
            if (!parse_value(out_value, 0)) { error = make_error(); return false; }
            skip_whitespace();
            if (position_ != text_.size()) { error = make_error() + " (extra content after root)"; return false; }
            return true;
        }
    private:
        static const int kMaxDepth = 64;
        void skip_whitespace() {
            while (position_ < text_.size()) {
                const unsigned char c = static_cast<unsigned char>(text_[position_]);
                if (c == ' ' || c == '\t' || c == '\n' || c == '\r') { ++position_; continue; }
                break;
            }
        }
        bool at_end() const { return position_ >= text_.size(); }
        bool parse_value(JsonValue& out_value, int depth) {
            if (depth > kMaxDepth) { error_ = "nesting too deep"; return false; }
            if (at_end()) { error_ = "unexpected end of file"; return false; }
            switch (text_[position_]) {
                case '{': return parse_object(out_value, depth);
                case '[': return parse_array(out_value, depth);
                case '"': out_value.type = JsonValue::Type::String; return parse_string(out_value.string_value);
                case 't': case 'f': return parse_bool(out_value);
                case 'n': return parse_null(out_value);
                default: return parse_number(out_value);
            }
        }
        bool parse_object(JsonValue& out_value, int depth) {
            out_value.type = JsonValue::Type::Object; ++position_; skip_whitespace();
            if (!at_end() && text_[position_] == '}') { ++position_; return true; }
            while (true) {
                skip_whitespace();
                if (at_end() || text_[position_] != '"') { error_ = "object key must be string"; return false; }
                std::string key; if (!parse_string(key)) return false;
                skip_whitespace();
                if (at_end() || text_[position_] != ':') { error_ = "missing ':' after key"; return false; }
                ++position_; skip_whitespace();
                JsonValue value; if (!parse_value(value, depth + 1)) return false;
                out_value.object_value.emplace_back(std::move(key), std::move(value));
                skip_whitespace();
                if (!at_end() && text_[position_] == ',') { ++position_; continue; }
                if (!at_end() && text_[position_] == '}') { ++position_; return true; }
                error_ = "missing ',' or '}' in object"; return false;
            }
        }
        bool parse_array(JsonValue& out_value, int depth) {
            out_value.type = JsonValue::Type::Array; ++position_; skip_whitespace();
            if (!at_end() && text_[position_] == ']') { ++position_; return true; }
            while (true) {
                skip_whitespace();
                JsonValue element; if (!parse_value(element, depth + 1)) return false;
                out_value.array_value.push_back(std::move(element));
                skip_whitespace();
                if (!at_end() && text_[position_] == ',') { ++position_; continue; }
                if (!at_end() && text_[position_] == ']') { ++position_; return true; }
                error_ = "missing ',' or ']' in array"; return false;
            }
        }
        bool parse_string(std::string& out_value) {
            ++position_; out_value.clear();
            while (!at_end()) {
                const unsigned char c = static_cast<unsigned char>(text_[position_]);
                if (c == '"') { ++position_; return true; }
                if (c == '\\') {
                    ++position_; if (at_end()) { error_ = "incomplete escape"; return false; }
                    const char escape = text_[position_++];
                    switch (escape) {
                        case '"': out_value.push_back('"'); break;
                        case '\\': out_value.push_back('\\'); break;
                        case '/': out_value.push_back('/'); break;
                        case 'b': out_value.push_back('\b'); break;
                        case 'f': out_value.push_back('\f'); break;
                        case 'n': out_value.push_back('\n'); break;
                        case 'r': out_value.push_back('\r'); break;
                        case 't': out_value.push_back('\t'); break;
                        case 'u': {
                            unsigned int code = 0; if (!parse_hex4(code)) return false;
                            if (code >= 0xD800 && code <= 0xDBFF) {
                                if (position_ + 1 >= text_.size() || text_[position_] != '\\' || text_[position_ + 1] != 'u') { error_ = "incomplete surrogate pair"; return false; }
                                position_ += 2; unsigned int low = 0; if (!parse_hex4(low)) return false;
                                if (low < 0xDC00 || low > 0xDFFF) { error_ = "invalid low surrogate"; return false; }
                                code = 0x10000U + ((code - 0xD800U) << 10) + (low - 0xDC00U);
                            }
                            append_utf8(out_value, code); break;
                        }
                        default: error_ = "unsupported escape char"; return false;
                    }
                    continue;
                }
                if (c < 0x20) { error_ = "unescaped control char in string"; return false; }
                out_value.push_back(static_cast<char>(c)); ++position_;
            }
            error_ = "unterminated string"; return false;
        }
        bool parse_hex4(unsigned int& out_code) {
            if (position_ + 4 > text_.size()) { error_ = "\\u too short"; return false; }
            unsigned int code = 0;
            for (int i = 0; i < 4; ++i) {
                const char h = text_[position_ + static_cast<size_t>(i)]; unsigned int digit = 0;
                if (h >= '0' && h <= '9') digit = static_cast<unsigned int>(h - '0');
                else if (h >= 'a' && h <= 'f') digit = static_cast<unsigned int>(h - 'a') + 10U;
                else if (h >= 'A' && h <= 'F') digit = static_cast<unsigned int>(h - 'A') + 10U;
                else { error_ = "non-hex char in \\u"; return false; }
                code = code * 16U + digit;
            }
            position_ += 4; out_code = code; return true;
        }
        static void append_utf8(std::string& out, unsigned int code) {
            if (code <= 0x7FU) { out.push_back(static_cast<char>(code)); }
            else if (code <= 0x7FFU) {
                out.push_back(static_cast<char>(0xC0U | (code >> 6))); out.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
            } else if (code <= 0xFFFFU) {
                out.push_back(static_cast<char>(0xE0U | (code >> 12))); out.push_back(static_cast<char>(0x80U | ((code >> 6) & 0x3FU))); out.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
            } else {
                out.push_back(static_cast<char>(0xF0U | (code >> 18))); out.push_back(static_cast<char>(0x80U | ((code >> 12) & 0x3FU))); out.push_back(static_cast<char>(0x80U | ((code >> 6) & 0x3FU))); out.push_back(static_cast<char>(0x80U | (code & 0x3FU)));
            }
        }
        bool parse_bool(JsonValue& out_value) {
            if (text_.compare(position_, 4, "true") == 0) { position_ += 4; out_value.type = JsonValue::Type::Bool; out_value.bool_value = true; return true; }
            if (text_.compare(position_, 5, "false") == 0) { position_ += 5; out_value.type = JsonValue::Type::Bool; out_value.bool_value = false; return true; }
            error_ = "invalid literal (expected true/false)"; return false;
        }
        bool parse_null(JsonValue& out_value) {
            if (text_.compare(position_, 4, "null") == 0) { position_ += 4; out_value.type = JsonValue::Type::Null; return true; }
            error_ = "invalid literal (expected null)"; return false;
        }
        bool parse_number(JsonValue& out_value) {
            const size_t start = position_; if (!at_end() && text_[position_] == '-') ++position_;
            if (at_end() || std::isdigit(static_cast<unsigned char>(text_[position_])) == 0) { position_ = start; error_ = "expected value"; return false; }
            bool is_integer = true;
            while (!at_end() && std::isdigit(static_cast<unsigned char>(text_[position_])) != 0) ++position_;
            if (!at_end() && text_[position_] == '.') {
                is_integer = false; ++position_;
                if (at_end() || std::isdigit(static_cast<unsigned char>(text_[position_])) == 0) { error_ = "missing digit after decimal"; return false; }
                while (!at_end() && std::isdigit(static_cast<unsigned char>(text_[position_])) != 0) ++position_;
            }
            if (!at_end() && (text_[position_] == 'e' || text_[position_] == 'E')) {
                is_integer = false; ++position_;
                if (!at_end() && (text_[position_] == '+' || text_[position_] == '-')) ++position_;
                if (at_end() || std::isdigit(static_cast<unsigned char>(text_[position_])) == 0) { error_ = "missing digit in exponent"; return false; }
                while (!at_end() && std::isdigit(static_cast<unsigned char>(text_[position_])) != 0) ++position_;
            }
            const std::string token = text_.substr(start, position_ - start);
            out_value.type = JsonValue::Type::Number;
            if (is_integer) {
                out_value.number_is_integer = true; out_value.integer_value = std::strtoll(token.c_str(), nullptr, 10); out_value.number_value = static_cast<double>(out_value.integer_value);
            } else {
                out_value.number_is_integer = false; out_value.number_value = std::strtod(token.c_str(), nullptr);
            }
            return true;
        }
        std::string make_error() const {
            size_t line = 1, column = 1;
            const size_t limit = position_ < text_.size() ? position_ : text_.size();
            for (size_t i = 0; i < limit; ++i) {
                if (text_[i] == '\n') { ++line; column = 1; } else { ++column; }
            }
            const std::string detail = error_.empty() ? "JSON syntax error" : error_;
            return "Line " + std::to_string(line) + ", Col " + std::to_string(column) + ": " + detail;
        }
        const std::string& text_; size_t position_ = 0; std::string error_;
    };

    void serialize_value(const JsonValue& val, std::ostringstream& oss, int indent_level) {
        std::string indent(indent_level * 2, ' ');
        std::string next_indent((indent_level + 1) * 2, ' ');
        switch (val.type) {
            case JsonValue::Type::Null: oss << "null"; break;
            case JsonValue::Type::Bool: oss << (val.bool_value ? "true" : "false"); break;
            case JsonValue::Type::Number:
                if (val.number_is_integer) oss << val.integer_value; else oss << val.number_value;
                break;
            case JsonValue::Type::String: oss << "\"" << val.string_value << "\""; break;
            case JsonValue::Type::Array:
                if (val.array_value.empty()) { oss << "[]"; break; }
                oss << "[\n";
                for (size_t i = 0; i < val.array_value.size(); ++i) {
                    oss << next_indent; serialize_value(val.array_value[i], oss, indent_level + 1);
                    if (i < val.array_value.size() - 1) oss << ",";
                    oss << "\n";
                }
                oss << indent << "]"; break;
            case JsonValue::Type::Object:
                if (val.object_value.empty()) { oss << "{}"; break; }
                // 【修改点】：取消对象内部的换行，改为横排
                oss << "{ ";
                for (size_t i = 0; i < val.object_value.size(); ++i) {
                    oss << "\"" << val.object_value[i].first << "\": ";
                    serialize_value(val.object_value[i].second, oss, indent_level);
                    if (i < val.object_value.size() - 1) oss << ", ";
                }
                oss << " }"; break;
        }
    }

    bool save_json_tree(const std::string& filepath, const JsonValue& root) {
        std::ofstream out(std::filesystem::u8path(filepath), std::ios::binary | std::ios::trunc);
        if (!out) return false;
        std::ostringstream oss;
        serialize_value(root, oss, 0);
        out << oss.str();
        return true;
    }

    JsonValue parse_literal(const std::string& literal) {
        JsonValue val; JsonParser parser(literal); std::string err;
        parser.parse(val, err); return val;
    }

    JsonValue* get_items_array(JsonValue& root) {
        if (root.type == JsonValue::Type::Array) return &root;
        if (root.type == JsonValue::Type::Object) {
            const JsonValue* items = root.find("items");
            if (items == nullptr) items = root.find("物品");
            if (items && items->type == JsonValue::Type::Array) return const_cast<JsonValue*>(items);
        }
        return nullptr;
    }

    const JsonValue* find_field(const JsonValue& object, const char* primary_key, const char* alias_key) {
        const JsonValue* field = object.find(primary_key);
        if (field == nullptr && alias_key != nullptr) field = object.find(alias_key);
        return field;
    }

    bool read_string_field(const JsonValue& object, const char* primary_key, const char* alias_key, std::string& out_value, std::string& error) {
        const JsonValue* field = find_field(object, primary_key, alias_key);
        if (field == nullptr) { error = std::string("Missing field \"") + primary_key + "\""; return false; }
        if (field->type != JsonValue::Type::String) { error = std::string("Field \"") + primary_key + "\" must be string"; return false; }
        out_value = field->string_value; return true;
    }

    bool items_from_root(const JsonValue& root, std::vector<Item>& out_items, std::string& error) {
        const JsonValue* rows = nullptr;
        if (root.type == JsonValue::Type::Array) { rows = &root; }
        else if (root.type == JsonValue::Type::Object) {
            rows = find_field(root, "items", "物品");
            if (rows == nullptr || rows->type != JsonValue::Type::Array) { error = "Root object must contain \"items\" array"; return false; }
        } else { error = "Root must be array or object with \"items\""; return false; }
        
        out_items.clear(); out_items.reserve(rows->array_value.size());
        for (size_t i = 0; i < rows->array_value.size(); ++i) {
            const JsonValue& row = rows->array_value[i];
            const std::string label = "Row " + std::to_string(i + 1);
            if (row.type != JsonValue::Type::Object) { error = label + " is not object"; return false; }
            Item item; std::string field_error;
            if (!read_string_field(row, "name", "名称", item.name, field_error)) { error = label + ": " + field_error; return false; }
            if (item.name.empty()) { error = label + ": name cannot be empty"; return false; }
            if (!read_string_field(row, "path", "路径", item.path, field_error)) { error = label + ": " + field_error; return false; }
            const JsonValue* price = find_field(row, "price", "价格");
            if (price == nullptr) { error = label + ": missing \"price\""; return false; }
            if (price->type != JsonValue::Type::Number || !price->number_is_integer) { error = label + ": \"price\" must be int"; return false; }
            item.price = static_cast<int>(price->integer_value);
            out_items.push_back(item);
        }
        return true;
    }
}

bool parse_items_json(const std::string& json_text, std::vector<Item>& out_items, std::string* error_message) {
    JsonValue root; std::string error;
    JsonParser parser(json_text);
    if (!parser.parse(root, error)) { if (error_message) *error_message = error; return false; }
    if (!items_from_root(root, out_items, error)) { if (error_message) *error_message = error; return false; }
    if (error_message) error_message->clear();
    return true;
}

bool load_from_json(ItemTableManager& table, const std::string& filepath, std::string* error_message) {
    std::ifstream input(std::filesystem::u8path(filepath), std::ios::binary);
    if (!input) { if (error_message) *error_message = "Cannot open file: " + filepath; return false; }
    const std::string text((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    std::vector<Item> items; std::string error;
    if (!parse_items_json(text, items, &error)) { if (error_message) *error_message = filepath + " " + error; return false; }
    table.clear();
    for (const Item& item : items) table.add_item(item);
    return true;
}

bool append_row_to_json(const std::string& filepath, const std::string& name, const std::string& path, int price, const std::map<std::string, std::string>& extra_columns) {
    JsonValue root;
    std::ifstream input(std::filesystem::u8path(filepath), std::ios::binary);
    if (input) {
        std::string text((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
        JsonParser parser(text); std::string err;
        if (!parser.parse(root, err)) return false;
    } else {
        root.type = JsonValue::Type::Object;
        JsonValue items_arr; items_arr.type = JsonValue::Type::Array;
        root.object_value.push_back({"items", items_arr});
    }
    JsonValue* rows = get_items_array(root);
    if (!rows) return false;

    JsonValue new_row; new_row.type = JsonValue::Type::Object;
    JsonValue v_name; v_name.type = JsonValue::Type::String; v_name.string_value = name; new_row.object_value.push_back({"name", v_name});
    JsonValue v_path; v_path.type = JsonValue::Type::String; v_path.string_value = path; new_row.object_value.push_back({"path", v_path});
    JsonValue v_price; v_price.type = JsonValue::Type::Number; v_price.number_is_integer = true; v_price.integer_value = price; new_row.object_value.push_back({"price", v_price});

    for (const auto& pair : extra_columns) {
        new_row.object_value.push_back({pair.first, parse_literal(pair.second)});
    }
    rows->array_value.push_back(std::move(new_row));
    return save_json_tree(filepath, root);
}

bool add_column_to_json(const std::string& filepath, const std::string& column_name, const std::string& default_value_json) {
    JsonValue root; std::ifstream input(std::filesystem::u8path(filepath), std::ios::binary);
    if (!input) return false;
    std::string text((std::istreambuf_iterator<char>(input)), std::istreambuf_iterator<char>());
    JsonParser parser(text); std::string err;
    if (!parser.parse(root, err)) return false;
    JsonValue* rows = get_items_array(root);
    if (!rows) return false;
    JsonValue default_val = parse_literal(default_value_json);

    for (auto& row : rows->array_value) {
        if (row.type == JsonValue::Type::Object) {
            if (row.find(column_name) == nullptr) {
                row.object_value.push_back({column_name, default_val});
            }
        }
    }
    return save_json_tree(filepath, root);
}