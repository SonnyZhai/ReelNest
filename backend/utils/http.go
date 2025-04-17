package utils

import (
	"bytes"
	"compress/flate"
	"compress/gzip"
	"encoding/json"
	"fmt"
	"io"
	"math/rand"
	"regexp"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/cloudwego/hertz/pkg/protocol"
)

// 预编译正则表达式提高性能
var (
	redirectRegex   = regexp.MustCompile(`window\.location\.href\s*=\s*["']([^"']+)["']`)
	htmlTagsRegex   = regexp.MustCompile(`<[^>]+>`)
	multiSpaceRegex = regexp.MustCompile(`\s+`)
)

var userAgents = []string{
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/123.0.0.0 Safari/537.36",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/113.0",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.4 Safari/605.1.15",
}

// DecompressBody 解压响应体
func DecompressBody(body []byte, contentEncoding string) ([]byte, error) {
	if contentEncoding == "" {
		return body, nil
	}

	var reader io.ReadCloser
	var err error

	switch contentEncoding {
	case "gzip":
		reader, err = gzip.NewReader(bytes.NewReader(body))
		if err != nil {
			return body, err
		}
	case "deflate":
		reader = flate.NewReader(bytes.NewReader(body))
	default:
		return body, nil
	}

	defer reader.Close()
	return io.ReadAll(reader)
}

// CleanHTML 清除HTML标签
func CleanHTML(input string) string {
	// 处理转义后的HTML标签
	input = strings.ReplaceAll(input, "<\\/", "</")

	// 使用正则表达式删除所有HTML标签
	text := htmlTagsRegex.ReplaceAllString(input, "")

	// 替换常见的HTML实体
	text = strings.ReplaceAll(text, "&nbsp;", " ")
	text = strings.ReplaceAll(text, "&amp;", "&")
	text = strings.ReplaceAll(text, "&lt;", "<")
	text = strings.ReplaceAll(text, "&gt;", ">")
	text = strings.ReplaceAll(text, "&quot;", "\"")

	// 移除多余的换行和空白
	text = multiSpaceRegex.ReplaceAllString(text, " ")
	text = strings.TrimSpace(text)

	return text
}

// CleanJSONString 清理 JSON 字符串中的 HTML 标签和转义字符
func CleanJSONString(jsonStr string) (string, error) {
	// 确保输入是有效的 UTF-8 编码
	if !utf8.ValidString(jsonStr) {
		// 尝试修复无效的 UTF-8 编码
		jsonStr = strings.Map(func(r rune) rune {
			if r == utf8.RuneError {
				return '�' // 替换为 Unicode 替换字符
			}
			return r
		}, jsonStr)
	}
	// 解析为通用 map 结构
	var data map[string]interface{}
	decoder := json.NewDecoder(strings.NewReader(jsonStr))
	decoder.UseNumber() // 保持数字类型不变
	if err := decoder.Decode(&data); err != nil {
		return "", fmt.Errorf("解析 JSON 失败: %w", err)
	}

	// 如果有 list 字段并且是数组
	if list, ok := data["list"].([]interface{}); ok {
		for i, item := range list {
			if videoItem, ok := item.(map[string]interface{}); ok {
				// 清理 vod_content 字段中的 HTML
				if content, ok := videoItem["vod_content"].(string); ok {
					// 替换转义的斜杠
					content = strings.ReplaceAll(content, "\\/", "/")

					// 清理 HTML 标签
					content = htmlTagsRegex.ReplaceAllString(content, "")

					// 替换 HTML 实体
					content = strings.ReplaceAll(content, "&nbsp;", " ")
					content = strings.ReplaceAll(content, "&amp;", "&")
					content = strings.ReplaceAll(content, "&lt;", "<")
					content = strings.ReplaceAll(content, "&gt;", ">")
					content = strings.ReplaceAll(content, "&quot;", "\"")

					// 处理多余的空白
					content = multiSpaceRegex.ReplaceAllString(content, " ")
					content = strings.TrimSpace(content)

					// 更新字段
					videoItem["vod_content"] = content
				}

				// 清理 URL 中的转义反斜杠
				cleanURLFields := []string{"vod_pic", "vod_play_url"}
				for _, field := range cleanURLFields {
					if url, ok := videoItem[field].(string); ok {
						videoItem[field] = strings.ReplaceAll(url, "\\/", "/")
					}
				}

				// 更新列表项
				list[i] = videoItem
			}
		}
		// 更新 list 字段
		data["list"] = list
	}

	// 重新序列化为 JSON
	cleanedJSON, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", fmt.Errorf("序列化 JSON 失败: %w", err)
	}

	return string(cleanedJSON), nil
}

// SplitToArray 将逗号分隔的字符串转换为字符串数组
func SplitToArray(input string) []string {
	if input == "" {
		return []string{}
	}

	parts := strings.Split(input, ",")
	result := make([]string, 0, len(parts))

	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}

	return result
}

// 获取随机的 User-Agent
func getRandomUserAgent() string {
	rand.Seed(time.Now().UnixNano())
	return userAgents[rand.Intn(len(userAgents))]
}

// AddBrowserHeaders 添加模拟浏览器的请求头
func AddBrowserHeaders(req *protocol.Request, referer string) {
	// 设置随机的 User-Agent
	userAgent := getRandomUserAgent()
	req.Header.Set("User-Agent", userAgent)
	req.Header.Set("Accept", "application/json, text/plain, */*")
	languages := []string{"zh-CN,zh;q=0.9,en;q=0.8", "en-US,en;q=0.9", "zh-TW,zh;q=0.9,en;q=0.8"}
	req.Header.Set("Accept-Language", languages[rand.Intn(len(languages))])
	req.Header.Set("sec-ch-ua", "\"Chromium\";v=\"122\", \"Google Chrome\";v=\"122\", \"Not:A-Brand\";v=\"99\"")
	req.Header.Set("sec-ch-ua-mobile", "?0")
	req.Header.Set("Sec-Fetch-Dest", "empty")
	req.Header.Set("Sec-Fetch-Mode", "cors")
	req.Header.Set("Sec-Fetch-Site", "same-origin")

	if referer != "" {
		req.Header.Set("Referer", referer)
		if strings.HasPrefix(referer, "http") {
			parts := strings.SplitN(referer, "/", 4)
			if len(parts) >= 3 {
				origin := parts[0] + "//" + parts[2]
				req.Header.Set("Origin", origin)
			}
		}
	}
}

// LogResponse 记录响应内容(有长度限制)
// func LogResponse(body []byte) {
// 	maxLogLength := 500 // 最大日志长度

// 	if len(body) <= maxLogLength {
// 		log.Printf("接收到响应体: %s", body)
// 		return
// 	}
// }
