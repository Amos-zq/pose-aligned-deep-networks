function [ch,img_id]=browse_hit_images(all_hits,im,visualize_hit_fn,visualize_all_hits_fn,params,img_id)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%% Interactive browsing of the hypotheses generated by the detection
%%% process.
%%%
%%% PARAMETERS:
%%%    all_hits:     A hit_list of the predicted bounds, torsos or poselet
%%%                  activations to display
%%%
%%% OPTIONAL PARAMETERS:
%%%    im:           If the test images are not enrolled (i.e. 
%%%                  do not appear in the global 'im' variable, you will
%%%                  need to create an im for them. See the file
%%%                  demo_poselets.m for how to do this.
%%%    visualize_hit_fn: 
%%%                  Function to call when zooming on a hypothesis
%%%    visualize_all_hits_fn: 
%%%                  Function to call to display multiple hypotheses
%%%
%%%    params:       Extra parameters, such as the list of detected
%%%                  poselets, torsos (for the person category), poselet
%%%                  masks and example poselets to help visualization. See
%%%                  demo_poselets.m for more.
%%%    img_id:       Which image to start displaying from (default: 1)
%%%
%%% Copyright (C) 2009, Lubomir Bourdev and Jitendra Malik.
%%% This code is distributed with a non-commercial research license.
%%% Please see the license file license.txt included in the source directory.
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~exist('im','var')
   global im;  %#ok<TLEV,REDEF>
end
    
image_ids = unique(all_hits.image_id);
if image_ids==0 % single image
   all_hits.image_id(:)=1; 
   image_ids=1;
end
if ~exist('params','var')
   params=[]; 
end
if ~isfield(params,'str')
    params.str='';
end

if ~exist('img_id','var')
   img_id=1; 
end
if ~exist('visualize_all_hits_fn','var') || isempty(visualize_all_hits_fn)
   visualize_all_hits_fn=@draw_bounds_of_hits; 
end

img_changed  = true;
num2show_changed = true;
%num2show = 1;

while 1
    if img_changed
        img = imread(image_file(image_ids(img_id),im)); %#ok<NODEF>
        hits_for_image = all_hits.select(all_hits.image_id==image_ids(img_id));
        num2show=1;
    end

    % Refresh image and redraw hit boxes
    if img_changed || num2show_changed
        figure(1);
        clf;
%        warning('off');
        imshow(rgb2gray(img));
%        warning('on');
        hold on;

        title(sprintf('img: %d imgid: %d showing: %d of %d %s',img_id,image_ids(img_id),num2show,hits_for_image.size,params.str));
        
        [srt,srtd] = sort(hits_for_image.score);
        visualize_all_hits_fn(hits_for_image.select(srtd((end-num2show+1):end)),params);
    end
    img_changed=false;
    num2show_changed = false;

    figure(1);
    while 1
        [x,y,ch] = ginput(1);
        if isscalar(ch) 
            break; 
        end
    end

    switch ch
        case 27 % ESC
            windows = 1:4;
            close(windows(ishandle(windows)));
            return;
        case 29 % ->
            if img_id<length(image_ids)
                img_id=img_id+1;
                img_changed=true;
            end

        case 28 % <-
            if img_id>1
                img_id=img_id-1;
                img_changed=true;
            end
        case 'g'
            answer = str2double(inputdlg('Enter index:'));
            if ~isempty(answer)
                answer = round(answer);
                if answer>0
                    img_id = min(answer,length(image_ids));
                    img_changed=true;
                end
            end
            
        case 1
            % find which bounds are selected
            [srt,srtd] = sort(hits_for_image.score,'descend');
            shown_hits = hits_for_image.select(srtd(1:num2show));
            intersect = find(x>=shown_hits.bounds(1,:) & y>=shown_hits.bounds(2,:) & x<=sum(shown_hits.bounds([1 3],:)) & y<=sum(shown_hits.bounds([2 4],:)));
            if ~isempty(intersect) && exist('visualize_hit_fn','var') && ~isempty(visualize_hit_fn)
                if length(intersect)>1
                   dst =  sum((shown_hits.bounds(1:2,intersect) + shown_hits.bounds(3:4,intersect)/2 - repmat([x;y],1,length(intersect))).^2);
                   selected_hit = shown_hits.select(intersect(find(dst==min(dst),1)));
                else
                   selected_hit = shown_hits.select(intersect);
                end
                visualize_hit_fn(selected_hit,img,params);
            end
        case 30 % /\
            num2show = num2show+1;
            num2show_changed=true;
        case 31 % \/
            if num2show>1
                num2show = max(1,num2show-1);
                num2show_changed=true;
            end
            
        otherwise
            return
    end %switch
end % while 1
end % main

function draw_bounds_of_hits(hits,params)
    hits.draw_bounds([1 0 0],3,'--',[.7 .9 .7]);
end