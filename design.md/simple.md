## api的自动生成；
1. interface定义的api， 有url作为annotation； 会自动生成http调用；
2. 对于返回值是obj:{list:,total}的自动生成带ctroller的函数 xxxFetch函数；函数会触发controller总页数变化；


## tableWidget生成
1. @TableWidget， 
2. 支持column的黑白名单，自动生成genHeader和genCell，build方法
3. 支持自动绑定onXXXTap响应函数；
4. 支持自动使用genXXXCell,返回格子的内容；
5. 支持自动使用showXXXCell，确定某个Column是否显示