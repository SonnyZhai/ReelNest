package config

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"sync"
)

// Config 应用配置
type Config struct {
	Port    int             `json:"port"`
	Timeout int             `json:"timeout_seconds"`
	Sites   map[string]Site `json:"sites"`
}

// Site API站点配置
type Site struct {
	Api    string `json:"api"`
	Name   string `json:"name"`
	Detail string `json:"detail"`
	Adult  bool   `json:"adult"`
}

const (
	VERSION = "1.0.0"
)

var (
	config     Config
	configLock sync.RWMutex
)

// Load 从文件加载配置
func Load(path string) error {
	configLock.Lock()
	defer configLock.Unlock()

	// 设置默认值
	config = Config{
		Port:    8080,
		Timeout: 30,
		Sites:   make(map[string]Site),
	}

	data, err := os.ReadFile(path)
	if err != nil {
		if os.IsNotExist(err) {
			log.Printf("警告: 配置文件 %s 不存在，使用默认配置", path)
			return nil
		}
		return fmt.Errorf("读取配置文件失败: %w", err)
	}

	// 解析配置文件
	var sitesMap map[string]Site
	if err := json.Unmarshal(data, &sitesMap); err != nil {
		return fmt.Errorf("解析配置文件失败: %w", err)
	}

	config.Sites = sitesMap
	log.Printf("成功加载 %d 个站点配置", len(sitesMap))
	return nil
}

// Get 获取当前配置
func Get() Config {
	configLock.RLock()
	defer configLock.RUnlock()
	return config
}

// GetSite 获取指定站点配置
func GetSite(siteKey string) (Site, bool) {
	configLock.RLock()
	defer configLock.RUnlock()
	site, ok := config.Sites[siteKey]
	return site, ok
}

// GetAllSites 获取所有站点配置
func GetAllSites() map[string]Site {
	configLock.RLock()
	defer configLock.RUnlock()

	// 返回一个拷贝而不是原始映射的引用
	sites := make(map[string]Site, len(config.Sites))
	for k, v := range config.Sites {
		sites[k] = v
	}
	return sites
}
