$(function(){
    $(document).bind('drop dragover', function (e) {
        e.preventDefault();
    });
    $(document).bind('dragover', function () {
        $('.main').addClass('drop');
    })
    $(document).bind('dragexit dragleave dragend drop', function () {
        $('.main').removeClass('drop');
    })

    var fileupload = $('#fileupload').fileupload({
        dataType: 'json',
        url: 'upload.json',
        dropZone: $(document),
        pasteZone: $(document),
        add: add
    });

    fileupload.bind('fileuploaddone', done);
    fileupload.bind('fileuploadfail', fail);
    fileupload.bind('fileuploadprogress', progress);

    var xhrCache = [];
    function add (e, data) {
        $('.message').hide();
        var xhr = data.submit();
        $.each(data.files, function(index, file){
            file._ID = xhrCache.length;
            xhrCache[file._ID] = xhr;
            var hasProgressbar = ('FormData' in window);
            var html = '<li data-file-id="' + file._ID + '">';
            html += '<div class="filename">' + file.name + '</div>';
            html += '<div class="progress"><div class="bar" style="width: 0%"></div>';
            if (!hasProgressbar) { html += '<span class="dots"></span>'; }
            html += '</div>';
            if (hasProgressbar) { html += '<div class="stop"></div>'; }
            html += '</li>';

            var tmpl = $(html);
            if (!hasProgressbar) {
                var progress = tmpl.find('.progress');
                var bar = progress.find('.bar');
                var dots = progress.find('.dots');

                function doting() {
                    if (bar.css('width') != '0px') { return; }

                    if (dots.text().length == 3) {
                        dots.text('');
                    }
                    else {
                        dots.text(dots.text() + '.');
                    }
                    setTimeout(doting, 750);
                }
                setTimeout(doting, 10);
            }
            $('.uploads ul').append(tmpl);
        });
    }

    function done (e, data) {
        $.each(data.files, function (index, file) {
            $('li[data-file-id=' + file._ID + ']').addClass('done');
        });
    }

    function progress (e, data) {
        var prog = Math.ceil(data.loaded / data.total * 100) + '%';
        $.each(data.files, function (index, file) {
            $('li[data-file-id=' + file._ID + '] .progress .bar').css('width', prog);
        });
    }

    function fail (e, data) {
        console.log('File transfer failed', data.errorThrown, data.textStatus);
        $.each(data.files, function (index, file) {
            $('li[data-file-id=' + file._ID + ']').addClass('fail');
        });
    }

    $('.uploads').delegate('.stop', 'click', stopTransfer);

    function stopTransfer (e) {
        var li = $(e.currentTarget).parent('li');
        var id = li.data('file-id');
        xhrCache[id].abort();
        li.addClass('fail');
    }
});