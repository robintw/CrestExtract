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

def append_arrays(array1, array2):
    for item in array2:
        array1.append(item)

    return array1

def reverse_array(array):
    res = arcpy.Array()
    for i in range(len(array) - 1, 0, -1):
        res.append(array[i])

    return res

def follow_line(row):
    global newLine
    # Do it by following the firstPoint
    get_points_from_line(row, first_points)
    print "Length of first points = ", len(newLine)
    first_points_line = newLine
    newLine = arcpy.Array()
    get_points_from_line(row, last_points)
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

    # Deal with how the points join up
    if points_equal(first_beg, last_beg):
        final_points_line = append_arrays(reverse_array(first_points_line), last_points_line)
    elif points_equal(first_end, last_beg):
        final_points_line = append_arrays(first_points_line, last_points_line)
    elif points_equal(first_end, last_end):
        final_points_line = append_arrays(first_points_line, reverse_array(last_points_line))
    elif points_equal(last_end, first_beg):
        final_points_line = append_arrays(last_points_line, first_points_line)

    # Add the new polyline to the list
    polyline = arcpy.Polyline(final_points_line)
    featureList.append(polyline)

    

def get_points_from_line(row, points_dict):
    global newLine
    oid = row.getValue(OIDField)
    print "Current OID = ", oid
    shape = row.getValue(shape_name)
    print "OID length = ", shape.length
    visited.append(oid)
    print "So far we have visited: ", visited

    
    for part in shape.getPart():
        for point in part:
            found_id = find_key(points_dict, point)
            print found_id

            if len(found_id) == 0:
                newLine.append(point)
                continue
            elif found_id[0] == oid:
                newLine.append(point)
                continue
            elif found_id[0] in visited:
                newLine.append(point)
                continue
            else:
                print "Yes: ", found_id
                print "Items in newLine = ", len(newLine)
                where = "\"" + str(OIDField) + "\" = " + str(found_id[0])
                print where
                found_object = arcpy.SearchCursor(input_lines, where)
                for item in found_object:
                    raw_input("Recursing:")
                    get_points_from_line(item, points_dict)        
        raw_input("Got to end of part:")

input_lines = "D:\\Data\\DunesGIS\\TestOverlaps.shp"
out_folder = "D:\\Data\\DunesGIS\\OutputOverlaps.shp"

featureList = []

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


for row in rows:
    print "%%%%%%%%%%%%%%%%% Starting new row in input %%%%%%%%%%"

    
    # Create the array to hold all the points that will be put
    # together in a line (eventually)
    newLine = arcpy.Array()

    # Do the work!
    follow_line(row)

print
print
print "Finished everything - about to write shapefile"
print len(featureList)
arcpy.CopyFeatures_management(featureList, "D:\AwesomeOutput23.shp")


del row
