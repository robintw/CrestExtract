import arcpy
from math import sqrt

def find_key(dict, val):
    return [k for k, v in dict.iteritems() if substract_points(v, val) < 0.1]

def subtract_points(p1, p2):
    dx = abs(p1.X - p2.X)
    dy = abs(p1.Y - p2.Y)

    return sqrt(dx * dx + dy * dy)

def points_equal(p1, p2):
    if subtract_points(p1, p2) < 0.1:
        return True
    else:
        return False

def print_point(point):
    print point.X, ", ", point.Y

def print_point_array(array):
    for point in array:
        print_point(point)

def append_arrays(array1, array2):
    array1.remove(len(array1) - 1)
    for item in array2:
        array1.append(item)

    return array1

def reverse_array(array):
    res = arcpy.Array()
    for i in range(len(array) - 1, -1, -1):
        res.append(array[i])

    return res

def follow_line(row):
    global newLine
    # Follow it using the first point
    get_points_from_line(row, "FIRST")
    print "Length of first points = ", len(newLine)
    first_points_line = newLine

    # Reset the newLine variable
    newLine = arcpy.Array()

    # Follow it using the last point
    get_points_from_line(row, "LAST")
    last_points_line = newLine

    first_beg = first_points_line[0]
    first_end = first_points_line[len(first_points_line) - 1]

    last_beg = last_points_line[0]
    last_end = last_points_line[len(last_points_line) - 1]

    
    print "%%%%%%%%%%%% DOING DECISION BIT"
    print "Beg and End of First Points Line"
    print "Beginning = ", first_points_line[0]
    print "End = ",first_points_line[len(first_points_line) - 1]

    print "Beg and End of Last Points Line"
    print "Beginning = ",last_points_line[0]
    print "End = ",last_points_line[len(last_points_line) - 1]

    if points_equal(first_beg, last_beg) and points_equal(first_end, last_end):
        print "We've only got one line here, so just use one of them"
        polyline = arcpy.Polyline(first_points_line)
        featureList.append(polyline)
        return

    print "#####################"
    print_point_array(first_points_line)
    print "#####################"
    print_point_array(last_points_line)
    
    # Deal with how the points join up
    if points_equal(first_beg, last_beg):
        final_points_line = append_arrays(reverse_array(first_points_line), last_points_line)
    elif points_equal(first_end, last_beg):
        final_points_line = append_arrays(first_points_line, last_points_line)
    elif points_equal(first_end, last_end):
        final_points_line = append_arrays(first_points_line, reverse_array(last_points_line))
    elif points_equal(last_end, first_beg):
        final_points_line = append_arrays(last_points_line, first_points_line)

    print "#####################"
    print "#####################"
    print_point_array(final_points_line)
    print "#####################"

    # Add the new polyline to the list
    polyline = arcpy.Polyline(final_points_line)
    print "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! Length of polyline: ", polyline.type, polyline.pointCount
    featureList.append(polyline)

    

def get_points_from_line(row, direction):
    global newLine
    oid = row.getValue(OIDField)
    print "Current OID = ", oid
    shape = row.getValue(shape_name)
    print "OID length = ", shape.length


    visited.append(oid)
    print "So far we have visited: ", visited


    for part in shape.getPart():
        if len(newLine) != 0:
            most_recently_visited_point = newLine[len(newLine) - 1]
            
            # Reverse array if needed here!
            if points_equal(most_recently_visited_point, shape.lastPoint):
                # Reverse the array
                print "!!!!!!! Reversing array"
                iter_part = reverse_array(part)
            elif points_equal(most_recently_visited_point, shape.firstPoint):
                iter_part = part
            else:
                print "EVERYTHING HAS GONE BADLY WRONG!"
                print most_recently_visited_point
                print shape.lastPoint
                print shape.firstPoint
        else:
            iter_part = part

        
        for point in iter_part:
            if direction == "LAST":
                found_id = find_key(last_points, point)
                print found_id
            elif direction == "FIRST":
                found_id = find_key(first_points, point)
                print found_id

            if len(found_id) == 0:
                print "At point:"
                print_point(point)
                print "Appending"
                newLine.append(point)
                continue
            elif found_id[0] == oid:
                print "At point:"
                print_point(point)
                print "Appending"
                newLine.append(point)
                continue
            elif found_id[0] in visited:
                print "At point:"
                print_point(point)
                print "Appending"
                newLine.append(point)
                continue
            else:
                newLine.append(point) # append point anyway
                print "Switching to original line with ID =: ", found_id
                print "Appending point below anyway:"
                print_point(point)
                where = "\"" + str(OIDField) + "\" = " + str(found_id[0])
                found_object = arcpy.SearchCursor(input_lines, where)
                for item in found_object:
                    raw_input("Recursing:")
                    get_points_from_line(item, direction)        
        raw_input("Got to end of part:")

input_lines = "D:\\Data\\DunesGIS\\TestOverlaps.shp"
out_folder = "D:\\Data\\DunesGIS\\OutputOverlaps.shp"



# Get the SearchCursor
rows = arcpy.SearchCursor(input_lines)


desc = arcpy.Describe(input_lines)

OIDField = desc.OIDFieldName

shape_name = arcpy.Describe(input_lines).shapeFieldName

first_points = {}
last_points = {}

# Iterate once first of all to get all of the first and last
# points into an array
for row in rows:
    shape = row.getValue(shape_name)   

    first_points[row.getValue(OIDField)] = shape.firstPoint
    last_points[row.getValue(OIDField)] = shape.lastPoint

visited = []

rows = arcpy.SearchCursor(input_lines)

featureList = []

for row in rows:
    

    oid = row.getValue(OIDField)

    if oid in visited:
        continue
    
    # Create the array to hold all the points that will be put
    # together in a line (eventually)
    newLine = arcpy.Array()

    print "%%%%%%%%%%%%%%%%% Starting new row in input %%%%%%%%%%"
    # Do the work!
    follow_line(row)

print
print
print "Finished everything - about to write shapefile"
print len(featureList)
arcpy.CopyFeatures_management(featureList, "D:\AwesomeOutput23.shp")


del row
