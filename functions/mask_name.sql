case 
    when input_name is null then null
    when length(input_name) <= 1 then input_name
    else concat(
        substr(input_name, 1, 1), 
        repeat('*', length(input_name) - 1)
    )
end