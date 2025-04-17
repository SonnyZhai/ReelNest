package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"ReelNest/config"
	"ReelNest/server"
)

func main() {
	// 加载配置
	if err := config.Load("../config/api_sites.json"); err != nil {
		log.Fatalf("加载配置失败: %v", err)
	}

	// 初始化并启动服务器
	srv := server.New()

	// 启动服务器(非阻塞)
	go func() {
		log.Printf("代理服务已启动: http://localhost:%d", config.Get().Port)
		if err := srv.Run(); err != nil {
			log.Fatalf("服务器启动失败: %v", err)
		}
	}()

	// 优雅退出处理
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)

	<-quit
	log.Println("正在关闭服务器...")

	// 留出5秒钟处理剩余请求
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := srv.Shutdown(ctx); err != nil {
		log.Fatalf("服务器强制关闭: %v", err)
	}

	log.Println("服务器已安全关闭")
}
