package models

// VideoInfo 视频详情信息
type VideoInfo struct {
	Title      string   `json:"title"`
	SubTitle   string   `json:"sub_title,omitempty"`
	Desc       string   `json:"desc"`
	SourceName string   `json:"source_name"`
	SourceCode string   `json:"source_code"`
	CoverUrl   string   `json:"cover_url,omitempty"`
	Year       string   `json:"year,omitempty"`
	Area       string   `json:"area,omitempty"`
	Directors  []string `json:"directors,omitempty"`
	Actors     []string `json:"actors,omitempty"`
	Type       string   `json:"type,omitempty"`
	Categories []string `json:"categories,omitempty"`
	Remarks    string   `json:"remarks,omitempty"`
	Duration   string   `json:"duration,omitempty"`
	Score      string   `json:"score,omitempty"`
}

// EpisodeInfo 剧集信息
type EpisodeInfo struct {
	Title string `json:"title"`
	Url   string `json:"url"`
}

// SpecialDetailResponse 特殊源详情响应
type SpecialDetailResponse struct {
	Code      int           `json:"code"`
	Episodes  []EpisodeInfo `json:"episodes"`
	DetailUrl string        `json:"detailUrl"`
	VideoInfo VideoInfo     `json:"videoInfo"`
}

// APIResponse API通用响应
type APIResponse struct {
	Code  int         `json:"code"`
	Msg   string      `json:"msg"`
	Total int         `json:"total,omitempty"`
	List  interface{} `json:"list,omitempty"`
}
