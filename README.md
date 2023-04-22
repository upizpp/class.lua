# class.lua
Help with object-oriented programming in Lua.

## Usage
`class:new`
新建一个类，传入一个arguments参数，  
这是一个表，它的第1号元素是类名，1号元素是父类（可选），剩余的是类成员。  
每个类成员函数的第一个参数必须是self，当前操作的类对象。  

返回一个类。  

可设置__metas__为类对象设置元方法（无法设置__index和__newindex）；  
可设置__setters__和__getters__设置类成员的setter和getter；  
每个setter函数的参数：self, value；  
每个gtter函数的参数：self；  

