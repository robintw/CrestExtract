import arcpy

def add_joining_lines(input_lines, max_distance):
    print "Starting add_joining_lines
    "
    points = "D:\\Data\\DunesGIS\\TempPoints.shp"

    # Convert the lines to points at each end
    arcpy.FeatureVerticesToPoints_management(input_lines,points,"BOTH_ENDS")

    # Generate the near table
    arcpy.Near_analysis(points, points, max_distance, True, True)

    # Get the SearchCursor to allow us to iterate over the points
    rows = arcpy.SearchCursor(points)

    # Also get an InsertCursor to allow us to add to the lines
    line_rows = arcpy.InsertCursor(input_lines)

    # Get the shape field name
    shape_name = arcpy.Describe(points).shapeFieldName

    # For each row (that is, each line in the input dataset)
    for row in rows:
        # Get the nearest point found
        new_x = row.getValue("NEAR_X")
        new_y = row.getValue("NEAR_Y")

        # If one or other of them is not valid then continue to next iteration
        if new_x == -1 or new_y == -1:
            continue

        # Get the current X and Y values
        part = row.getValue(shape_name).getPart()
        current_x = part.X
        current_y = part.Y

        
        #print new_x, new_y, " : ", current_x, current_y

        # Add the points to a new array of points for the line
        lineArray = arcpy.Array()

        first = arcpy.Point(X=current_x, Y=current_y)
        last = arcpy.Point(X=new_x, Y=new_y)

        lineArray.add(first)
        lineArray.add(last)    

        # Insert the new line into the dataset
        feat = line_rows.newRow()
        feat.shape = lineArray
        line_rows.insertRow(feat)


    # Clean up
    del line_rows
    del rows

    print "Done"

