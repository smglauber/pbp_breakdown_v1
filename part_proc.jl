
using CSV
using DataFrames
using Dates

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

function get_halfs(file)
   df = CSV.File(file, delim='\t') |> DataFrame
   deleterows!(df, findall(x->x=="play", df[1]))   # drop rows with 'play'
   indexes   = [1,3,4]                             # only keep the relevant cols
   sec_index = findall(x->x=="2nd Half", df[1])[1] # findall returns array
   ot_index  = findall(x->x=="OT", df[1])[1]

   half_1 = df[1:sec_index-1, indexes]             # +-1,2 is to drop the extra headers
   half_2 = df[sec_index+2:ot_index-1, indexes]
   half_3 = df[ot_index+2:end, indexes]

   function converttime!(f)
      dt = DateFormat("M:S")
      old = copy(f[1])
      f[1] = Vector{Union{Missing, DateTime}}(undef, length(old))
      for i=1:length(old)
         println(old[i])
         f[1][i] = DateTime(old[i], dt)
      end
   end

   converttime!(half_1)
   converttime!(half_2)
   converttime!(half_3)

   return half_1, half_2, half_3
end

curdir = pwd() # Sets the directory target to the current working directory
game = uigetfile(curdir) # Asks for a text file
println("$game")

half_1, half_2, half_3 = get_halfs(game)

