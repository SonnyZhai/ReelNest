package server

import (
	"context"
	"fmt"
	"time"

	"github.com/cloudwego/hertz/pkg/app"
	"github.com/cloudwego/hertz/pkg/app/client"
	"github.com/cloudwego/hertz/pkg/app/middlewares/server/recovery"
	"github.com/cloudwego/hertz/pkg/app/server"
	"github.com/hertz-contrib/cors"

	"ReelNest/config"
	"ReelNest/handlers"
)

// Server 应用服务器
type Server struct {
	h      *server.Hertz
	client *client.Client
}

// New 创建新的服务器实例
func New() *Server {
	cfg := config.Get()

	// 创建HTTP客户端
	hzClient, err := client.NewClient(
		client.WithDialTimeout(5*time.Second),
		client.WithResponseBodyStream(true),
		client.WithMaxIdleConnDuration(time.Minute),
		client.WithMaxConnsPerHost(100),
		client.WithTLSConfig(nil),
	)
	if err != nil {
		panic(fmt.Sprintf("创建HTTP客户端失败: %v", err))
	}

	// 创建服务器
	h := server.New(server.WithHostPorts(fmt.Sprintf(":%d", cfg.Port)))

	// 添加中间件
	h.Use(recovery.Recovery()) // 异常恢复
	h.Use(cors.Default())      // CORS支持

	// 创建实例
	srv := &Server{
		h:      h,
		client: hzClient,
	}

	// 设置路由
	srv.setupRoutes()

	return srv
}

// Run 启动服务器
func (s *Server) Run() error {
	return s.h.Run()
}

// Shutdown 优雅关闭服务器
func (s *Server) Shutdown(ctx context.Context) error {
	return s.h.Shutdown(ctx)
}

// setupRoutes 设置路由
func (s *Server) setupRoutes() {
	// 健康检查接口
	s.h.GET("/health", func(ctx context.Context, c *app.RequestContext) {
		c.JSON(200, map[string]string{"status": "ok"})
	})

	// 版本信息接口
	s.h.GET("/version", func(ctx context.Context, c *app.RequestContext) {
		c.JSON(200, map[string]string{
			"version": config.VERSION,
			"app":     "ReelNest Backend",
		})
	})

	// API列表接口
	s.h.GET("/api/sites", func(ctx context.Context, c *app.RequestContext) {
		result := make([]map[string]interface{}, 0)
		for id, site := range config.GetAllSites() {
			result = append(result, map[string]interface{}{
				"id":     id,
				"name":   site.Name,
				"detail": site.Detail,
				"adult":  site.Adult,
			})
		}
		c.JSON(200, result)
	})

	// 特殊处理接口 - 处理特定的API请求
	s.h.GET("/api/special-detail", handlers.NewSpecialHandler(s.client))

	// 主代理接口 - 支持所有HTTP方法
	s.h.Any("/api/proxy", handlers.NewProxyHandler(s.client))
}
