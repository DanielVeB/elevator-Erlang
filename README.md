# Erlang - elevator

## Description

Final project for concurrent and distributed programming course
at the AGH University of Science and Technology. 
## About

The project presents simulations of elevators movement using concurrent programming.
Program is written in erlang - concurrent and functional programming language, so we can easily simulate as many elevators as we want.
Each elevator in system is self-sufficient process so it is independent from the other processes.
## How to use

###Install erlang
If you don't have yet, install Erlang
#### For Ubuntu
`apt-get install erlang`
#### For HomeBrew on OSX
`brew install erlang`
#### For Fedora
`yum install erlang`

You can also visit [erlang.org/downloads](https://www.erlang.org/downloads) to get more information.

###Run program

 Open a terminal, go to directory where the program is and then type in 
 `erl` 

Then, you have to compile modules, write <br/>
 `c(elevator).` <br/>
 and <br/>
 `c(main).`
 
 Then write:
 `main:sim({Min, Max}, Number).` <br/>
 where
  
 *Min* - Lowest floor, 
 
 *Max* - highest floor,
  
 *Number* - number of elevators. 
 
 
 