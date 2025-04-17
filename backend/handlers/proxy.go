package handlers

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log"
	"strings"
	"time"

	"github.com/cloudwego/hertz/pkg/app"
	"github.com/cloudwego/hertz/pkg/app/client"
	"github.com/cloudwego/hertz/pkg/protocol"

	"ReelNest/config"
	"ReelNest/utils"
)

// NewProxyHandler 创建代理处理器
func NewProxyHandler(client *client.Client) func(context.Context, *app.RequestContext) {
	return func(ctx context.Context, c *app.RequestContext) {
		proxyHandler(ctx, c, client)
	}
}

// proxyHandler 处理代理请求
func proxyHandler(ctx context.Context, c *app.RequestContext, client *client.Client) {
	site := string(c.Query("site"))
	customAPI := string(c.Query("custom_api"))
	path := string(c.Query("path"))
	query := string(c.Query("query"))

	startTime := time.Now()
	method := string(c.Method())

	// 确定目标API基础URL
	var base string
	if customAPI != "" {
		base = customAPI
	} else if site != "" {
		siteConfig, ok := config.GetSite(site)
		if !ok {
			c.String(400, "未知数据源: %s", site)
			return
		}
		base = siteConfig.Api
	} else {
		c.String(400, "缺少数据源参数，请提供 site 或 custom_api")
		return
	}

	// 拼接目标URL
	targetURL := buildTargetURL(base, path, query)

	// 创建带超时的上下文
	cfg := config.Get()
	reqCtx, cancel := context.WithTimeout(ctx, time.Duration(cfg.Timeout)*time.Second)
	defer cancel()

	req, resp := protocol.AcquireRequest(), protocol.AcquireResponse()
	defer protocol.ReleaseRequest(req)
	defer protocol.ReleaseResponse(resp)

	// 设置请求信息
	req.SetRequestURI(targetURL)
	req.SetMethod(method)

	// 转发常见请求头
	c.Request.Header.VisitAll(func(key, value []byte) {
		keyStr := string(key)
		// 跳过一些不需要转发的头部
		if keyStr != "Connection" && keyStr != "Host" {
			req.Header.Set(keyStr, string(value))
		}
	})

	// 对于POST/PUT等请求，转发请求体
	if method == "POST" || method == "PUT" || method == "PATCH" {
		req.SetBody(c.Request.Body())
		req.Header.Set("Content-Type", "application/json")
	}

	// 添加浏览器请求头
	utils.AddBrowserHeaders(req, base)

	// 执行请求
	if err := client.Do(reqCtx, req, resp); err != nil {
		handleRequestError(c, err, method, targetURL)
		return
	}

	// 处理响应
	if err := handleResponse(ctx, c, resp, site, path, query, client); err != nil {
		c.String(500, "处理响应失败: %v", err)
		return
	}

	// 记录请求信息
	duration := time.Since(startTime)
	log.Printf("代理请求 %s %s -> %s 状态码:%d 耗时:%v",
		method, c.Path(), targetURL, resp.StatusCode(), duration)
}

// buildTargetURL 构建目标URL
func buildTargetURL(base, path, query string) string {
	targetURL := base

	// 处理路径
	if path != "" {
		if !strings.HasSuffix(base, "/") && !strings.HasPrefix(path, "/") {
			targetURL += "/"
		}
		targetURL += path
	}

	// 添加查询参数
	if query != "" {
		if strings.Contains(targetURL, "?") {
			targetURL += "&" + query
		} else {
			targetURL += "?" + query
		}
	}

	return targetURL
}

// handleRequestError 处理请求错误
func handleRequestError(c *app.RequestContext, err error, method, targetURL string) {
	if errors.Is(err, context.DeadlineExceeded) {
		c.String(504, "请求超时")
	} else {
		c.String(502, "上游请求失败: %v", err)
	}
	log.Printf("代理请求失败 %s %s -> %s: %v", method, c.Path(), targetURL, err)
}

// handleResponse 处理响应
func handleResponse(ctx context.Context, c *app.RequestContext, resp *protocol.Response, site, path, query string, client *client.Client) error {
	// 设置响应状态码
	c.Status(resp.StatusCode())

	// 转发响应头
	resp.Header.VisitAll(func(key, value []byte) {
		c.Header(string(key), string(value))
	})

	// 读取响应体
	body, err := io.ReadAll(resp.BodyStream())
	if err != nil {
		return fmt.Errorf("读取响应失败: %w", err)
	}

	// 处理压缩内容
	contentEncoding := string(resp.Header.Peek("Content-Encoding"))
	if contentEncoding != "" {
		decompressedBody, err := utils.DecompressBody(body, contentEncoding)
		if err == nil && len(decompressedBody) > 0 {
			body = decompressedBody
			c.Header("Content-Encoding", "")
		} else {
			log.Printf("解压失败: %v", err)
		}
	}

	// 记录响应内容(适当长度)
	// if resp.StatusCode() == 200 {
	// 	utils.LogResponse(body)
	// }

	// 设置响应体
	c.Header("Content-Length", fmt.Sprintf("%d", len(body)))
	c.Write(body)

	return nil
}