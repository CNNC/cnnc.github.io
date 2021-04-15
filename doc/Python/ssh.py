#!/usr/bin/env python
# _*_ coding:utf8 _*_
#author:snate
cnt=0;
alex_age=50
while cnt<3:
   guess_age =int(input("请输入您猜测的年龄："))
   if alex_age==guess_age:
      print("You are lucky,you got it");
      break
   elif alex_age>guess_age:
      print("Think bigger");
   else:
      print("think smaller");
   cnt += 1
else:
   print("Your input number is too much,fuck off!")