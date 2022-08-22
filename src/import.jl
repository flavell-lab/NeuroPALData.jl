function get_neuron_roi(roi)
    if isa(roi, AbstractString)
        if occursin("/", roi)
            return parse.(Int, split(roi, "/"))
        else
            return [parse(Int, roi)]
        end
    elseif isa(roi, Int)
        return [roi]
    elseif isa(roi, Float64)
        if isinteger(roi)
            return [convert(Int, roi)]
        else
            error("ROI($roi) is not integer")
        end
    else
        error("unknown data type for neuron ROI")
    end
end

function import_neuropal_label(path_label::String)
    if endswith(path_label, ".xlsx")
        list_sheets = XLSX.openxlsx(path_label, mode="r") do xlsx
            XLSX.sheetnames(xlsx)
        end
        list_sheets_label = sort(filter(x->occursin("labels",x) && !occursin("progress",x), list_sheets))
        sheet_ = list_sheets_label[end]
        println("reading $(sheet_) for $path_label")
        sheet_label = XLSX.readtable(path_label, sheet_)
        col_label = sheet_label.column_labels
        data_ = vcat(reshape(string.(col_label), (1,length(col_label))),
            hcat(sheet_label.data...))
        
        import_neuropal_label(data_)
    elseif endswith(path_label, ".csv")
        data_ = readdlm(path_label, ',')
        import_neuropal_label(data_)
    else
        error("unsupported data type. supported: csv, xlsx")
    end
end

function import_neuropal_label(data_::Matrix)
    neuropal_roi_to_label = Dict{Int, Vector{Dict}}()
    list_roi = get_neuron_roi.(data_[2:end,3])

    for roi_id = sort(unique(vcat(list_roi...)))
        idx_row_match = findall(roi_id .∈ list_roi)        
        list_match = Dict{String,Any}[]

        for i_row = (idx_row_match .+ 1) # offset column label
            label = data_[i_row,1]
            neuron_class, DV, LR = get_neuron_class(label)
            roi_id_ = data_[i_row,3]
            confidence = data_[i_row,4]
            comment = data_[i_row,5]
            region = data_[i_row,6]
            
            match_ = Dict{}()
            match_["label"] = label
            match_["roi_id"] = get_neuron_roi(roi_id_)
            match_["confidence"] = confidence
            match_["region"] = region
            match_["neuron_class"] = neuron_class
            match_["LR"] = LR
            match_["DV"] = DV
            
            push!(list_match, match_)
        end        
        
        neuropal_roi_to_label[roi_id] = list_match
    end
    
    neuropal_label_to_roi = Dict{String, Any}()
    list_class = map(x->get_neuron_class(x)[1], data_[2:end, 1])
    for class = unique(list_class)
        idx_row_match = findall(class .== list_class)
        list_match = Dict{String,Any}[]
        for i_row = (idx_row_match .+ 1) # offset column label
            label = data_[i_row,1]
            neuron_class, DV, LR = get_neuron_class(label)
            roi_id_ = data_[i_row,3]
            confidence = data_[i_row,4]
            comment = data_[i_row,5]
            region = data_[i_row,6]

            match_ = Dict{}()
            match_["label"] = label
            match_["roi_id"] = get_neuron_roi(roi_id_)
            match_["confidence"] = confidence
            match_["region"] = region
            match_["neuron_class"] = neuron_class
            match_["LR"] = LR
            match_["DV"] = DV

            # println("$label, $DV - $(typeof(DV))")
            push!(list_match, match_)
        end        

        neuropal_label_to_roi[class] = list_match
    end
    
    neuropal_roi_to_label, neuropal_label_to_roi
end
