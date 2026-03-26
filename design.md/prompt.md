```
// @gos type=servlet; url=/user
type UserServlet struct{}

// 方法 url 为 /info → 完整 URL：/user/info
// @gos url=/info; method=GET; title="查询用户信息"
func (u *UserServlet) GetInfo(ctx context.Context, req *GetInfoReq) (*User, error) {
    // 业务逻辑...
}
```