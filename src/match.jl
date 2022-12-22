function match_roi(list_roi, roi_match, roi_match_confidence, θ_confidence=2)
    roi_match_ = 0
    match_conf_ = 0.
    for roi = list_roi
        if roi_match_confidence[roi] > match_conf_
            match_conf_ = roi_match_confidence[roi]
            roi_match_ = roi_match[roi]
        end
    end
    
    if roi_match_ != 0 && match_conf_ >= θ_confidence
        return roi_match_, match_conf_
    else
        return false, match_conf_
    end
end

"""
    get_list_match_dict(list_neuropal_label, list_class_ordered)

Return a list of dictionaries with the matching labels for each class

# Arguments
- `list_neuropal_label`: list of neuropal labels
- `list_data_dict`: list of data dictionaries
- `list_dict_fit`: list of fit dictionaries
- `list_class_ordered`: out of `get_list_class_ordered`
- `list_class_classify_dv_enc`: list of classes to classify D/V using encodding
- `θ_confidence`: confidence threshold for roi matching (default: 2.)
- `θ_confidence_label`: confidence threshold for label matching (default: 2.)
"""
function get_list_match_dict(list_neuropal_label; list_data_dict, list_dict_fit, list_class_ordered,
    list_class_classify_dv_enc, θ_confidence = 2., θ_confidence_label = 2.)
    list_match_dict = []

    for (idx_uid, dict_neuropal) = enumerate(list_neuropal_label)
        data_dict =  list_data_dict[idx_uid]
        neuropal_reg = data_dict["neuropal_registration"]
        dict_fit = list_dict_fit[idx_uid]
        roi_match = neuropal_reg["roi_match"]
        roi_match_confidence = neuropal_reg["roi_match_confidence"]

        match_roi_class = Dict()
        match_class_roi = Dict()
        
        for (idx_class, (class, class_name, class_dv)) = enumerate(list_class_ordered)
            if haskey(dict_neuropal[2], class)
                list_label = dict_neuropal[2][class]
                list_match = get_label_class(class, class_dv, list_label,
                    roi_match, roi_match_confidence, θ_confidence,
                    dict_fit, list_class_classify_dv_enc)            

                match_ = []
                for match = list_match
                    (roi_gcamp, match_confidence) = match_roi(match["roi_id"], roi_match, roi_match_confidence, θ_confidence)
                    if isa(roi_gcamp, Int) && match["confidence"] >= θ_confidence_label && !occursin("alt", match["label"])
                        push!(match_, (match, roi_gcamp, match_confidence))
                        match_roi_class[roi_gcamp] = match
                    end # check if matchable
                end # check match

                # if class ∈ NeuroPALData.LIST_REF_CLASS_DV
                if length(match_) > 0
                    if !(isnothing(class_dv)) && class_dv !== "undefined"
                        match_class_roi[class * class_dv] = match_
                    else    
                        match_class_roi[class] = match_
                    end
                end
            end # has key class
        end # if class is labeled
        
        push!(list_match_dict, (match_roi_class, match_class_roi))
    end # for dataset
    
    return list_match_dict
end