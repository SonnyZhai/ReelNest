package handlers

import (
	"context"
	"fmt"
	"io"
	"log"
	"regexp"
	"strings"
	"time"

	"github.com/cloudwego/hertz/pkg/app"
	"github.com/cloudwego/hertz/pkg/app/client"
	"github.com/cloudwego/hertz/pkg/protocol"

	"ReelNest/config"
	"ReelNest/models"
	"ReelNest/utils"
)

// 预编译正则表达式以提高性能
var (
	ffzyRegex    = regexp.MustCompile(`\$(https?:\/\/[^"'\s]+?\/\d{8}\/\d+_[a-f0-9]+\/index\.m3u8)`)
	generalRegex = regexp.MustCompile(`\$(https?:\/\/[^"'\s]+?\.m3u8)`)
	titleRegex   = regexp.MustCompile(`<h1[^>]*>([^<]+)</h1>`)
	descRegex    = regexp.MustCompile(`<div[^>]*class=["']sketch["'][^>]*>([\s\S]*?)</div>`)
)

// NewSpecialHandler 创建特殊源处理器
func NewSpecialHandler(client *client.Client) func(context.Context, *app.RequestContext) {
	return func(ctx context.Context, c *app.RequestContext) {
		handleSpecialSourceDetail(ctx, c, client)
	}
}

// handleSpecialSourceDetail 处理特殊源的详情页面解析
func handleSpecialSourceDetail(ctx context.Context, c *app.RequestContext, client *client.Client) {
	// 获取请求参数
	id := string(c.Query("id"))
	sourceCode := string(c.Query("source"))

	if id == "" || sourceCode == "" {
		c.JSON(400, models.APIResponse{
			Code: 400,
			Msg:  "缺少必要参数 id 或 source",
		})
		return
	}

	// 检查是否支持该源
	siteConfig, ok := config.GetSite(sourceCode)
	if !ok {
		c.JSON(400, models.APIResponse{
			Code: 400,
			Msg:  "不支持的源: " + sourceCode,
		})
		return
	}

	// 根据源类型选择不同的处理方法
	switch sourceCode {
	case "ffzy", "dbzy":
		handleAPISourceDetail(ctx, c, client, id, sourceCode, siteConfig)
	default:
		handleHTMLSourceDetail(ctx, c, client, id, sourceCode, siteConfig)
	}
}

// handleAPISourceDetail 处理使用API获取详情的特殊源
func handleAPISourceDetail(ctx context.Context, c *app.RequestContext, client *client.Client, id, sourceCode string, siteConfig config.Site) {
	// 构建 API URL
	apiUrl := siteConfig.Api
	if !strings.HasSuffix(apiUrl, "/") {
		apiUrl += "/"
	}
	apiUrl += "api.php/provide/vod/?ac=videolist&ids=" + id

	// 设置超时上下文
	reqCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	// 创建请求
	req, resp := protocol.AcquireRequest(), protocol.AcquireResponse()
	defer protocol.ReleaseRequest(req)
	defer protocol.ReleaseResponse(resp)

	req.SetRequestURI(apiUrl)
	req.SetMethod("GET")
	utils.AddBrowserHeaders(req, "")

	// 执行请求
	if err := client.Do(reqCtx, req, resp); err != nil {
		c.JSON(500, models.APIResponse{
			Code: 500,
			Msg:  "获取详情失败: " + err.Error(),
		})
		return
	}

	// 检查响应状态
	if resp.StatusCode() != 200 {
		c.JSON(resp.StatusCode(), models.APIResponse{
			Code: resp.StatusCode(),
			Msg:  "API 请求失败，状态码: " + fmt.Sprint(resp.StatusCode()),
		})
		return
	}

	// 读取响应体
	body, err := io.ReadAll(resp.BodyStream())
	if err != nil {
		c.JSON(500, models.APIResponse{
			Code: 500,
			Msg:  "读取 API 响应失败: " + err.Error(),
		})
		return
	}

	// 清理 JSON 中的 HTML 和转义字符
	cleanedJSON, err := utils.CleanJSONString(string(body))
	if err != nil {
		log.Printf("清理 JSON 失败: %v, 将使用原始数据继续", err)
		cleanedJSON = string(body)
	}

	// log.Printf("返回的json结果: %s", cleanedJSON)
	// 返回结果
	c.Header("Content-Type", "application/json; charset=utf-8")
	c.Data(200, "application/json", []byte(cleanedJSON))
}

// handleHTMLSourceDetail 处理需要解析HTML的特殊源
func handleHTMLSourceDetail(ctx context.Context, c *app.RequestContext, client *client.Client, id, sourceCode string, siteConfig config.Site) {
	// 确保有详情页URL
	if siteConfig.Detail == "" {
		c.JSON(400, models.APIResponse{
			Code: 400,
			Msg:  "该源未配置详情页URL",
		})
		return
	}

	// 构建详情页URL
	detailUrl := buildDetailUrl(siteConfig.Detail, id)

	// 设置超时上下文
	reqCtx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	// 创建请求
	req, resp := protocol.AcquireRequest(), protocol.AcquireResponse()
	defer protocol.ReleaseRequest(req)
	defer protocol.ReleaseResponse(resp)

	req.SetRequestURI(detailUrl)
	req.SetMethod("GET")
	utils.AddBrowserHeaders(req, siteConfig.Detail)

	// 执行请求
	if err := client.Do(reqCtx, req, resp); err != nil {
		c.JSON(500, models.APIResponse{
			Code: 500,
			Msg:  "获取详情页失败: " + err.Error(),
		})
		return
	}

	// 检查响应状态
	if resp.StatusCode() != 200 {
		c.JSON(resp.StatusCode(), models.APIResponse{
			Code: resp.StatusCode(),
			Msg:  "详情页请求失败，状态码: " + fmt.Sprint(resp.StatusCode()),
		})
		return
	}

	// 读取响应体
	html, err := io.ReadAll(resp.BodyStream())
	if err != nil {
		c.JSON(500, models.APIResponse{
			Code: 500,
			Msg:  "读取详情页内容失败: " + err.Error(),
		})
		return
	}

	// 解析HTML内容
	episodes := parseHTMLForEpisodes(html, sourceCode)
	title, desc := extractTitleAndDesc(html)

	// 构建响应
	response := models.SpecialDetailResponse{
		Code:      200,
		Episodes:  convertStringsToEpisodes(episodes),
		DetailUrl: detailUrl,
		VideoInfo: models.VideoInfo{
			Title:      title,
			Desc:       desc,
			SourceName: siteConfig.Name,
			SourceCode: sourceCode,
		},
	}

	// 返回结果
	c.JSON(200, response)
}

// buildDetailUrl 构建详情页URL
func buildDetailUrl(baseUrl, id string) string {
	if !strings.HasSuffix(baseUrl, "/") {
		baseUrl += "/"
	}
	return baseUrl + "index.php/vod/detail/id/" + id + ".html"
}

// parseEpisodes 解析播放链接为剧集列表
func parseEpisodes(playURL string) []models.EpisodeInfo {
	episodes := make([]models.EpisodeInfo, 0)

	// 分割多组播放源
	playURLs := strings.Split(playURL, "$$$")
	if len(playURLs) == 0 {
		return episodes
	}

	// 使用第二组链接（m3u8格式），如果有的话
	playURLIndex := 0
	if len(playURLs) > 1 {
		playURLIndex = 1 // 使用第二组链接，通常是m3u8格式
	}

	// 分割各集链接
	episodeLinks := strings.Split(playURLs[playURLIndex], "#")
	for _, episodeLink := range episodeLinks {
		parts := strings.Split(episodeLink, "$")
		if len(parts) > 1 {
			// 添加播放链接
			episodes = append(episodes, models.EpisodeInfo{
				Title: parts[0],
				Url:   parts[1],
			})
		}
	}

	return episodes
}

// parseHTMLForEpisodes 从HTML中解析剧集链接
func parseHTMLForEpisodes(html []byte, sourceCode string) []string {
	htmlStr := string(html)
	var episodes []string

	// 根据不同源类型使用不同的正则表达式
	if sourceCode == "ffzy" {
		// 非凡影视使用特定的正则表达式
		matches := ffzyRegex.FindAllStringSubmatch(htmlStr, -1)
		for _, match := range matches {
			if len(match) > 1 {
				episodes = append(episodes, match[1])
			}
		}
	}

	// 如果没有找到链接或者是其他源类型，尝试一个更通用的模式
	if len(episodes) == 0 {
		matches := generalRegex.FindAllStringSubmatch(htmlStr, -1)
		for _, match := range matches {
			if len(match) > 1 {
				episodes = append(episodes, match[1])
			}
		}
	}

	// 去重处理
	return removeDuplicateEpisodes(episodes)
}

// removeDuplicateEpisodes 去除重复链接
func removeDuplicateEpisodes(episodes []string) []string {
	uniqueEpisodes := make([]string, 0)
	episodeMap := make(map[string]bool)

	for _, episode := range episodes {
		// 处理链接，去除括号后面的内容
		if parenIndex := strings.Index(episode, "("); parenIndex > 0 {
			episode = episode[:parenIndex]
		}

		if _, exists := episodeMap[episode]; !exists {
			episodeMap[episode] = true
			uniqueEpisodes = append(uniqueEpisodes, episode)
		}
	}

	return uniqueEpisodes
}

// extractTitleAndDesc 提取标题和描述
func extractTitleAndDesc(html []byte) (string, string) {
	htmlStr := string(html)

	// 提取标题
	titleMatch := titleRegex.FindStringSubmatch(htmlStr)
	title := ""
	if len(titleMatch) > 1 {
		title = strings.TrimSpace(titleMatch[1])
	}

	// 提取描述
	descMatch := descRegex.FindStringSubmatch(htmlStr)
	desc := ""
	if len(descMatch) > 1 {
		desc = utils.CleanHTML(descMatch[1])
	}

	return title, desc
}

// convertStringsToEpisodes 将字符串数组转换为剧集信息
func convertStringsToEpisodes(urls []string) []models.EpisodeInfo {
	episodes := make([]models.EpisodeInfo, len(urls))
	for i, url := range urls {
		episodes[i] = models.EpisodeInfo{
			Title: fmt.Sprintf("第%d集", i+1),
			Url:   url,
		}
	}
	return episodes
}
