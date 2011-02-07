FUNCTION RUN_COLLAPSE, binary_image, slope_image, gap
    ; Create two copies of the binary image to use in the processing below
    ; as the routine modifies the image provided to it
    horiz_binary = binary_image
    vert_binary = binary_image
    
    ; Get the fitness image by processing the slope image
    fitness = GET_FITNESS_IMAGE(slope_image)
    
    indices = WHERE(binary_image EQ 0, count)
    IF count GT 0 THEN fitness[indices] = 0
    
    ; Run the collapse routine in both directions
    collapse, fitness, horiz_binary, gap, 0, xmax, ymax
    
    collapse, fitness, vert_binary, 0, gap, xmax, ymax
    
    ; Combine the results
    binary = horiz_binary OR vert_binary
    
    return, binary
END