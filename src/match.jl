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