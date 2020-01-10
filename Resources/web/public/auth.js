var is_banned = false;

function show_loader(show) {
    if (show) {
        $("#code").hide();
        $("#code_bgd").hide();
        $("#loader").show();
    } else {
        if (!is_banned) {
            $("#code").show();
            $("#code_bgd").show();
        }
        $("#loader").hide();
    }
}

function show_authentification_failed(json) {
    var html = json.message;
    html += json.remainingAttempts;
    $("#message").html(html);
    if (json.result == "ban") {
        is_banned = true;
        $("#code").hide();
        $("#code_bgd").hide();
    }
    $("#code").val("");
    show_loader(false);
}

function authenticate() {
    show_loader(true);
    $.get("/public/auth.html", {
          code: $("#code").val()
    },
    function(response) {
        var json = JSON.parse(response);
        switch (json.result) {
            case "ok":
                window.location.replace("/");
                break;
            case "ko":
                show_authentification_failed(json);
                break;
            case "ban":
                show_authentification_failed(json);
                break;
        }
    });
}

function update_field() {
    let bgds = [$(".bgd0"), $(".bgd1"), $(".bgd2"), $(".bgd3")];

    for (var i = 0; i < 4; ++i) {
        if (i == $("#code").val().length) {
            bgds[i].addClass("bgd_selected");
        } else {
            bgds[i].removeClass("bgd_selected");
        }
    }
}

function check_passcode_complete() {
    if (!is_banned) {
        if ($("#code").val().length >= 4) {
            authenticate();
        }
        update_field();
    }
}

/*
 * Monitor keypress to enter passcode without clicking the field
 */
$(document).keypress(function(e) {
    if (!is_banned) {
        if (e.target != $("#code")[0]) {
            $("#code").val($("#code").val() + e.key);
            check_passcode_complete();
        }
    }
});

/*
 * Prevent backspace to navigate back
 */
$(document).on("keydown", function (e) {
    if (e.which === 8 && !$(e.target).is("input")) {
        e.preventDefault();
        $("#code").val($("#code").val().slice(0,-1));
        check_passcode_complete();
    }
});

/*
 * Monitor form and input when entering passcode with focus on the field
 */
$(function() {
  $("#code_form").submit(check_passcode_complete);
  $("#code").change(check_passcode_complete);
  $("#code").on("input", check_passcode_complete);
});
