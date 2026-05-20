var is_banned = false;
var passcode_length = 4;

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
    update_field();
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
    var entered = $("#code").val().length;
    for (var i = 0; i < passcode_length; ++i) {
        var cell = $(".bgd" + i);
        if (i == entered) {
            cell.addClass("bgd_selected");
        } else {
            cell.removeClass("bgd_selected");
        }
    }
}

function check_passcode_complete() {
    if (!is_banned) {
        if ($("#code").val().length >= passcode_length) {
            authenticate();
        }
        update_field();
    }
}

function build_passcode_cells() {
    var parsed = parseInt($("#code_bgd").attr("data-length"), 10);
    if (parsed > 0) {
        passcode_length = parsed;
    }

    var container = $("#code_bgd");
    container.empty();
    for (var i = 0; i < passcode_length; ++i) {
        var cell = $("<div></div>").addClass("code_bgd bgd" + i);
        if (i === 0) {
            cell.addClass("bgd_selected");
        }
        if (i === passcode_length - 1) {
            cell.addClass("last_bgd");
        }
        container.append(cell);
    }

    // Scale layout for 6-digit passcodes so cells fit alongside the input.
    var cell_size = passcode_length > 4 ? 70 : 100;
    var cell_gap = passcode_length > 4 ? 24 : 33;
    var font_size = passcode_length > 4 ? 70 : 100;
    var letter_spacing = passcode_length > 4 ? 51 : 75;
    var padding_left = passcode_length > 4 ? 60 : 80;

    var cells_width = passcode_length * cell_size + (passcode_length - 1) * cell_gap;
    var input_width = cells_width + padding_left + cell_gap;

    container.css({ "width": cells_width + "px", "height": cell_size + "px",
                    "margin-top": -cell_size + "px" });
    $(".code_bgd").css({ "width": cell_size + "px", "height": cell_size + "px",
                         "margin-right": cell_gap + "px" });
    $(".last_bgd").css({ "margin-right": "0" });
    $("#code").css({ "width": input_width + "px", "height": cell_size + "px",
                     "font-size": font_size + "px",
                     "letter-spacing": letter_spacing + "px",
                     "padding-left": padding_left + "px" });
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
  build_passcode_cells();
  $("#code_form").submit(check_passcode_complete);
  $("#code").change(check_passcode_complete);
  $("#code").on("input", check_passcode_complete);
});
