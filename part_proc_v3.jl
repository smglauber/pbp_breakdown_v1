
"""
take a directory a input and navigate internal files; returns a string
"""
function uigetfile(dir)
   !isdir(dir) && begin warn("Input not a directory"); return "" end
   ls = readdir(dir)                                                     # returns everything in the input directory as a vector
   ls = filter( x->!isdir(dir*x), ls)                                    # filter out directories to isolate files in the list
   length(ls) == 0 && begin warn("No files in directory"); return "" end # if no files, print message
   if length(ls) > 99                                                     # if we have too many files to list, ignore for now!
      println("homework for sam!")
      return ""
   else
      for (i,f) in enumerate(ls)                                         # enumerate over all things in the vector
         println("[$i]: $f")
      end
      println("\nSelect a file: ")
      selection = tryparse(Int, readline())                              # readline() waits for input; try to parse input as Int
      selection != nothing && return ls[selection]                       # if good selection, return it
      warn("Bad selection")
      return ""
   end
end

curdir = pwd() # Sets the directory target to the current working directory
game = uigetfile(curdir) # Asks for a text file
println("$game")
gametxt = open(game) do file
    read(file, String)
end
lines = split(gametxt,"\n")
line = length(lines)

global homescore = zeros(line) # Home team score
global awayscore = zeros(line) # Away team score
global gentime = zeros(line) # Time in seconds
global margin = zeros(line) # Superfulous, but used slightly differently than Home - Away

# println("Total number of lines: $(line)")
global (Alast,Hlast) = (0.0,0.0) #Values to be pulled for the first loop

# ESPN's syntax after string separation is "MM:SS\t...\tAA - HH\t\r" for valid lines
# Initial values
global (ot,flag,Mlast,Slast,Alast,Hlast) = (0,0,40.0,0.0,0.0,0.0)

for step in 1:1:line
  lnstub = lines[step]
  tmpar = split(lnstub,"\t") # spits out an array breaking up the line by tabs
  if last(tmpar) == "\r" #Indicates that there is play-by-play data on this line
    timesect = 1 #Time values are reported as "MM:SS" in the first block of the array
    scoresect = length(tmpar)-1
    if flag == 0
      temp1 = split(tmpar[timesect],':')
      (minu,sec) = (parse(Float64,temp1[1]),parse(Float64,temp1[2]))
      minu = minu + 20
      temp2 = split(tmpar[scoresect]," - ")
      (AA,HH) = (parse(Float64,temp2[1]),parse(Float64,temp2[2]))
    elseif ot == 1
      (minu,sec) = (0.0,0.0)
      (AA,HH) = (Alast,Hlast)
    else
      temp1 = split(tmpar[timesect],':')
      (minu,sec) = (parse(Float64,temp1[1]),parse(Float64,temp1[2]))
      temp2 = split(tmpar[scoresect]," - ")
      (AA,HH) = (parse(Float64,temp2[1]),parse(Float64,temp2[2]))
    end
  elseif (last(tmpar) == "SCORE\r") && (flag == 0) # First line
    (minu,sec) = (40.0,0.0)
    (AA,HH) = (0.0,0.0)
  elseif (last(tmpar) == "2nd Half\r") # Halftime line
    flag = 1
    (minu,sec) = (20.0,0.0)
    (AA,HH) = (Alast,Hlast)
  elseif (last(tmpar) == "OT\r")
    ot = 1
    (minu,sec) = (0.0,0.0)
    (AA,HH) = (Alast,Hlast)
  elseif (step == line) && ot == 0 # End of Game, no "\r" at the end
    timesect = 1
    scoresect = length(tmpar)
    temp1 = split(tmpar[1],':')
    (minu,sec) = (parse(Float64,temp1[1]),parse(Float64,temp1[2]))
    temp2 = split(tmpar[scoresect]," - ")
    (AA,HH) = (parse(Float64,temp2[1]),parse(Float64,temp2[2]))
  elseif (step == line)
    (minu,sec) = (0.0,0.0)
    (AA,HH) = (Alast,Hlast)
  else # "Play\r" and additional "SCORE\r"  lines and any other crap
    (minu,sec) = (Mlast,Slast)
    (AA,HH) = (Alast,Hlast)
  end
  HMar = HH - AA
  tsecs = minu * 60.0 + sec
  global (Hlast,Alast) = (HH,AA)
  homescore[step] = HH
  awayscore[step] = AA
  gentime[step] = tsecs
  margin[step] = HMar
  global (flag,ot) = (flag,ot)
end

# Final processing section
invtime = (2400*ones(line)) - gentime # A timescale that counts up in seconds
global (start,total,subblock) = (1,0.0,0.0)

for j = 2:1:length(invtime)
    if (margin[j] != margin[j-1]) && (invtime[j] != invtime[start]) # don't do anything until there is a different start time
        global subblock = margin[j-1]*(invtime[j]-invtime[start])
        global start = j
    elseif (margin[j] != margin[j-1]) # Primarily foul shots or immediate putbacks
        global start = j
        global subblock = 0.0 # No time has elapsed
    elseif j == length(invtime) # Check to pick up any additional lead picked up by last team to score
        global subblock = margin[j]*(invtime[j]-invtime[start])
    else # steals, misses, time outs, etc.
        global subblock = 0.0
    end
    global total = total + subblock
    #println("$subblock")
    #println("$total")
end
avemarg = total/2400.0
round(avemarg, digits=4);
