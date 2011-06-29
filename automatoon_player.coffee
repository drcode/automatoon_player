automatoon_player={}
do ->
        browser_android=((navigator.userAgent.search 'Android')!=-1)
        browser_ie=$.browser.msie?
        browser_ios=((navigator.userAgent.search 'iPad')!=-1)or((navigator.userAgent.search 'iPhone')!=-1)
        browser_mozilla=$.browser.mozilla?
        browser_webkit=$.browser.webkit? and !browser_android and !browser_ios
        stopped=true
        divider=null
        directory=null
        transition_msec=100
        animation_width=1000
        heartbeat_mode=browser_ie or browser_android or browser_mozilla or browser_ios
        if browser_mozilla
                browser_prefix='-moz-'
        else
                browser_prefix='-webkit-'
        heartbeat_mode_steps=3
        partial=(f,partial_arguments...)->
                ->
                        f.apply this,[partial_arguments...,arguments...]
        parse_mstr=(mstr)->
                if !mstr?
                        return
                arr=mstr.split /,|\(|\)/
                for x in [arr[1],arr[3],arr[5],arr[2],arr[4],arr[6]]
                        parseFloat x
        set_transform=(img,mstr)->
                if heartbeat_mode
                        matrix=parse_mstr mstr
                        img.data 'dst_matrix',matrix
                        ie_step_transition img,heartbeat_mode_steps-1,0
                else
                        img.css browser_prefix+'transform',mstr
        ie_init_transition=(img,mstr)->
                img.data 'src_matrix',(img.data 'dst_matrix')
                matrix=parse_mstr mstr
                img.data 'dst_matrix',matrix
        lerp_scalar=(lerp_fraction,a,b)->
                a+(b-a)*lerp_fraction
        lerp_geometric=(lerp_fraction,a,b)->
                a*(Math.pow b/a,lerp_fraction)
        lerp_point=(lerp_fraction,[x1,y1],[x2,y2])->
                [(lerp_scalar lerp_fraction,x1,x2),(lerp_scalar lerp_fraction,y1,y2)]
        lerp_angle=(lerp_fraction,angle1,angle2)->
                angle_delta=angle2-angle1
                while angle_delta<0
                        angle_delta+=2*Math.PI
                while angle_delta>=2*Math.PI
                        angle_delta-=2*Math.PI
                if angle_delta>=Math.PI
                        angle_delta-=2*Math.PI
                angle1+(angle_delta*lerp_fraction)
        matrix_angle=(matrix)->
                Math.atan2 matrix[3],matrix[4]
        matrix_position=(matrix)->
                [matrix[2],matrix[5]]
        matrix_scale=(matrix)->
                Math.sqrt (matrix[0]*matrix[0]+matrix[1]*matrix[1])
        matrix_string=(matrix)->
                'matrix('+matrix[0].toFixed(5)+','+matrix[3].toFixed(5)+','+matrix[1].toFixed(5)+','+matrix[4].toFixed(5)+','+matrix[2].toFixed(5)+','+matrix[5].toFixed(5)+')'
        transform_point=([x1,x2],[a11,a12,a13,a21,a22,a23])->
                x3=1
                [a11*x1+a12*x2+a13*x3,a21*x1+a22*x2+a23*x3]
        ie_step_transition=(img,step,opacity)->
                if step==heartbeat_mode_steps-1
                        matrix=img.data 'dst_matrix'
                else
                        src_matrix=img.data 'src_matrix'
                        dst_matrix=img.data 'dst_matrix'
                        if !src_matrix?
                                matrix=dst_matrix
                        else
                                src_angle=matrix_angle src_matrix
                                src_position=matrix_position src_matrix
                                src_scale=matrix_scale src_matrix
                                dst_angle=matrix_angle dst_matrix
                                dst_position=matrix_position dst_matrix
                                dst_scale=matrix_scale dst_matrix
                                lerp_fraction=(step+1)/heartbeat_mode_steps
                                angle=lerp_angle lerp_fraction,src_angle,dst_angle
                                position=lerp_point lerp_fraction,src_position,dst_position
                                scale=lerp_geometric lerp_fraction,src_scale,dst_scale
                                sin=(Math.sin angle)*scale
                                cos=(Math.cos angle)*scale
                                matrix=[cos,-sin,position[0],sin,cos,position[1]]
                if !matrix?
                        return
                if !browser_ie
                        mstr=matrix_string matrix
                        img.css browser_prefix+'transform',mstr
                else
                        img.get(0).runtimeStyle.filter="progid:DXImageTransform.Microsoft.Matrix(enabled=false)"
                        wold=do img.width
                        hold=do img.height
                        ptgoal=transform_point [wold/2,hold/2],matrix
                        img.get(0).runtimeStyle.filter="progid:DXImageTransform.Microsoft.Matrix(M11='"+matrix[0].toFixed(5)+"',M12='"+matrix[1].toFixed(5)+"',M21='"+matrix[3].toFixed(5)+"',M22='"+matrix[4].toFixed(5)+"', sizingMethod='auto expand')progid:DXImageTransform.Microsoft.Alpha(Opacity="+opacity+")"
                        w=do img.width
                        h=do img.height
                        img.css
                                left:ptgoal[0]-w/2
                                top:ptgoal[1]-h/2
        preload_frame=(parent,animation,time)->
        preload_frame=(parent,animation,time)->
                enable_transition=(obj)->
                        if heartbeat_mode
                                return
                        obj.css browser_prefix+'transition',browser_prefix+'transform '+transition_msec+'ms linear,opacity '+transition_msec+'ms linear'
                {images,tweens,frames}=animation
                {additions,deletions,transformations,morph_starts,morph_stops,morphings,order}=frames[time]
                for {part_id,image_id,matrix} in additions
                        img=$('<img></img>')
                        img.attr 'id','automatoon_'+time+'_part_'+part_id
                        parent.append(img)
                        img.addClass('automatoon_'+time)
                        img.css browser_prefix+'transform-origin','0 0'
                        img.css
                                display:'none'
                                position:'absolute'
                        if images?
                                image=images[image_id]
                                img.attr 'src',image.get(0).toDataURL()
                        else
                                img.attr 'src',directory+'images'+divider+image_id
                        set_transform img,matrix
                        enable_transition img
                for {part_id,image_id,image_id_2,matrix_2,matrix} in morph_starts
                        if image_id_2?
                                if image_id?
                                        img_tween=$('<img></img>')
                                        img_tween.attr 'id','automatoon_'+time+'_part_'+part_id+'_tween'
                                        parent.append img_tween
                                        img_tween.addClass('part')
                                        img_tween.addClass('automatoon_'+time)
                                        img_tween.css browser_prefix+'transform-origin','0 0'
                                        img_tween.css
                                                display:'none'
                                                position:'absolute'
                                        if tweens?
                                                tween=tweens[[part_id,image_id,image_id_2]].image
                                                img_tween.attr 'src',tween.get(0).toDataURL()
                                        else
                                                img_tween.attr 'src',directory+'parts'+divider+part_id+divider+'srcimages'+divider+image_id+divider+'dstimages'+divider+image_id_2
                                        set_transform img_tween,matrix
                                        enable_transition img_tween
                                img_2=$('<img></img>')
                                img_2.attr 'id','automatoon_'+time+'_part_'+part_id+'_2'
                                img_2.addClass('automatoon_'+time)
                                parent.append img_2
                                img_2.css browser_prefix+'transform-origin','0 0'
                                img_2.css
                                        position:'absolute'
                                        opacity:0
                                        display:'none'
                                if images?
                                        image_2=images[image_id_2]
                                        img_2.attr 'src',image_2.get(0).toDataURL()
                                else
                                        img_2.attr 'src',directory+'images'+divider+image_id_2
                                set_transform img_2,matrix_2
                                enable_transition img_2
        prepare_frame=(parent,animation,time)->
                {images,tweens,frames}=animation
                {additions,deletions,transformations,morph_starts,morph_stops,morphings,order}=frames[time]
                for {part_id,image_id,matrix} in additions
                        img=$ '#automatoon_'+time+'_part_'+part_id
                        img.attr 'id','animpart_'+part_id
                        img.css
                                display:'inline'
                for {part_id} in deletions
                        do $('#animpart_'+part_id).remove
                for {part_id} in morph_stops
                        $('#animpart_'+part_id).remove()
                        $('#animpart_'+part_id+'_2').attr 'id','animpart_'+part_id
                        $('#animpart_'+part_id).css 'opacity',1
                        $('#animpart_'+part_id+'_tween').remove()
                for {part_id,image_id,image_id_2,matrix_2} in morph_starts
                        if image_id_2?
                                if image_id?
                                        img_tween=$ '#automatoon_'+time+'_part_'+part_id+'_tween'
                                        img_tween.attr 'id','animpart_'+part_id+'_tween'
                                        img_tween.css
                                                display:'inline'
                                img_2=$ '#automatoon_'+time+'_part_'+part_id+'_2'
                                img_2.attr 'id','animpart_'+part_id+'_2'
                                img_2.css
                                        display:'inline'
                for part_id,n in order
                        s='#animpart_'+part_id
                        $(s+'_tween').css
                                'z-index':n*3+2
                        $(s+'_2').css
                                'z-index':n*3+3
                        $(s).css
                                'z-index':n*3+4
        transition_frame=(parent,animation,time)->
                {images,tweens,frames}=animation
                {additions,deletions,transformations,morph_starts,morph_stops,morphings,order}=frames[time]
                for {part_id,lerp_fraction,matrix_2} in morphings
                        $('#animpart_'+part_id).css 'opacity',1-lerp_fraction
                        img_2=$('#animpart_'+part_id+'_2')
                        img_2.css 'opacity',lerp_fraction
                        set_transform img_2,matrix_2
                for part_id,matrix of transformations
                        img=$('#animpart_'+part_id)
                        set_transform img,matrix
                        img_tween=$('#animpart_'+part_id+'_tween')
                        if img_tween.get(0)?
                                set_transform img_tween,matrix
        heartbeat_mode_transition_frame=(state,step)->
                {parent,animation,time}=state
                {images,tweens,frames}=animation
                {additions,deletions,transformations,morph_starts,morph_stops,morphings,order}=frames[time]
                opacities={}
                for {part_id,lerp_fraction,matrix_2} in morphings
                        op=Math.floor((1-lerp_fraction)*100)
                        opacities[part_id]=op
                        $('#animpart_'+part_id).css
                                'opacity':1-lerp_fraction
                                filter: 'alpha(opacity='+op+')'
                        img_2=$('#animpart_'+part_id+'_2')
                        op=Math.floor(lerp_fraction*100)
                        img_2.css
                                'opacity':lerp_fraction
                                filter: 'alpha(opacity='+op+')'
                        if step==0
                                ie_init_transition img_2,matrix_2
                        ie_step_transition img_2,step,op
                for part_id,matrix of transformations
                        img=$('#animpart_'+part_id)
                        if step==0
                                ie_init_transition img,matrix
                        op=opacities[part_id]
                        if !op?
                                op=100
                        ie_step_transition img,step,op
                        img_tween=$('#animpart_'+part_id+'_tween')
                        if img_tween.get(0)?
                                if step==0
                                        ie_init_transition img_tween,matrix
                                ie_step_transition img_tween,step,100
                step_nu=step+1
                if step_nu==heartbeat_mode_steps
                        state.time++
                        setTimeout (partial animate,state),1
                else
                        setTimeout (partial heartbeat_mode_transition_frame,state,step_nu),transition_msec/heartbeat_mode_steps
        animate=(state)->
                {parent,time,animation}=state
                {images,frames}=animation
                if time==frames.length
                        time=state.time=0
                        do parent.empty
                if time==0
                        for t in [0...frames.length]
                                preload_frame parent,animation,t
                prepare_frame parent,animation,time
                setTimeout (partial animate_transition,state),1
        animate_transition=(state)->
                if stopped
                        return
                {parent,time,animation}=state
                {images,frames}=animation
                if heartbeat_mode
                        setTimeout (partial heartbeat_mode_transition_frame,state,0),transition_msec/heartbeat_mode_steps
                else
                        transition_frame parent,animation,time
                        state.time++
                        setTimeout (partial animate,state),transition_msec
        play_helper=(params)->
                k=
                        time:0
                        container:$ "body"
                params=$.extend k,params
                {animation,hosted,script,time,container}=k
                if hosted?
                        divider='/'
                        directory=''
                else
                        divider='_'
                        directory=safe_dirname script+'/'
                do ($ ".automatoon_wrapper").remove
                parent=$ "<div></div>"
                parent.addClass "automatoon_wrapper"
                wid=do container.width
                container.append parent
                zoom=wid/animation_width
                parent.css
                        zoom:zoom
                        '-moz-transform':'scale('+zoom+')'
                k.parent=parent
                animate k
        safe_dirname=(s)->
                s.replace /\ /g,'_'
        automatoon_player.play=(params,container)->
                stopped=false
                if ($.type params)=='string'
                        params=
                                script:params
                if container?
                        params.container=container
                if params.animation?
                        play_helper params
                else
                        if params.hosted?
                                url='script'
                        else
                                url=(safe_dirname params.script)+'/script'
                        $.getJSON url,(animation)->
                                params.animation=animation
                                play_helper params
        automatoon_player.stop=->
                stopped=true
