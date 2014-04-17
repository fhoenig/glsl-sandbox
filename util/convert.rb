#
# convert Phasespace mocap data to simple binary format
#

# assumes 480hz of data input and writes out 60hz
downSample = 8

filename = ARGV[0]

# check commandline argumets
if ARGV.length != 1
    puts "Usage convert.rb <filename>"
    exit
end

puts "Converting: " + filename + "..."

if File.exists?(filename) == false
    puts filename + "not readable"
    exit
end

file = File.open(filename, "r")

frameNum = 0
framesWritten = 0
index = Hash.new

animData = Array.new
lastGood = Hash.new

file.each do |line|
    
    frame = line.scan(/f\s(\d+)/)
    
    if (frame.length > 0)
        puts "Frame " + frame[0][0]
        frameNum = Integer(frame[0][0])
        frameData = lastGood.values
        if (frameData.length > 0 and frameNum % downSample == 0)
            animData << frameData
            frameData = []
            framesWritten += 1
        end
    end
    
    # vertex data line
    vertexData = line.scan(/m\s([\d,a-z]+),\s+([\d,\.,\-]+),\s+([\d,\.,\-]+)\s+([\d,\.,\-]+)\s+([\d,\.,\-]+).*/)

    if (vertexData.length > 0)
        confid = vertexData[0][1].to_f
        sensorId = Integer(vertexData[0][0])
        if (confid > 1.0 or index.has_key?(sensorId) == true)
            # got a positive confidence value, so this sensor ID is alive or being used
            # or the sensorid has a previous value, so use it regardless
            index[sensorId] = true
            lastGood[sensorId] = [vertexData[0][2].to_f, vertexData[0][3].to_f,vertexData[0][4].to_f] unless confid < 1.0
        end
        #puts "Vertex " + vertexData[0][0] + " ("+ vertexData[0][2] + ", " + vertexData[0][4] + ", " + vertexData[0][3] +")"
    end
    
    # if (frameNum > 100)
    #      break
    # end
end

file.close()

# verify data integrity
numSensors = animData[0].length
print "Checking integrity for " + (frameNum+1).to_s + " frames and " + numSensors.to_s + "sensors..."
animData.each do |sensorVector|
    if (sensorVector.length != numSensors)
        puts "Inconsistent sensor vector length"
        exit
    end
end
puts "valid."

# debug
# puts animData.inspect
# puts animData.length

#write binary file output
output = File.open(filename.split(".")[0]+".mocap", "w")

# write int32 number of frames
output.write([framesWritten].pack("l"))

# write int32 number of sensors 
output.write([numSensors].pack("l"))

# write each frame's sensorVector
animData.each do |sensorVector|
    sensorVector.each do |position|
        # puts position.length
        # puts position[0].to_s + " " + position[1].to_s + " " + position[2].to_s
        # puts position.pack("fff")
        output.write(position.pack("fff"))
    end
end
output.close
# write out binary file



