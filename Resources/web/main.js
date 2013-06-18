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
            var html = '<li data-file-id="' + file._ID + '">';
            html += '<div class="filename">' + file.name + '</div>';
            html += '<div class="progress"><div class="bar" style="width: 0%"></div></div>';
            html += '<div class="stop"></div>';
            html += '</li>';
            var tmpl = $(html);
            $('.uploads ul').append(html);
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