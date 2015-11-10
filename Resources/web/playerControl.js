$(function() {

    /**
     * Ws is a wrapper of the WebSocket API
     * @class Ws
     */
    var Ws = function(options, managerOptions) {
        options = options || {};
        managerOptions = managerOptions || {};

        if (!options.url)
            throw "Cannot open a socket without a url";

        //@TODO: add try catch & retry
        this.onMessageCallbacks = [];
        this.socket = new WebSocket(options.url);
        this.url = options.url;
        this.maxTry = 4;
        this.recoTry = 0;
    };

    /**
     * @method init
     */
    Ws.prototype.init = function() {
        var self = this;
        this.socket.onopen = function() {
            self._onOpen(this);
        };

        this.socket.onmessage = function(e) {
            self.onMessage(e);
        };

        this.socket.onclose = function() {
            self._onClose();
        };

        this.socket.onerror = function(error) {
            self._onError(error);
        };
    };

    /**
     * @method _onOpen
     * @param {Object} e
     * @private
     */
    Ws.prototype._onOpen = function(e) {
        console.log(e);
        this.recoTry = 0;
    };

    /**
     * On message call message callbacks
     * @method onMessage
     * @param {Object} e
     */
    Ws.prototype.onMessage = function(e) {
        //@TODO: is json?
        var message = $.parseJSON(e.data);
        for (var i = 0, length = this.onMessageCallbacks.length; i < length; i++) {
            var cb = this.onMessageCallbacks[i];
            if (typeof cb === 'function') {
                cb(message);
            }
        }
    };

    /**
     * @method _onError
     * @param {Object} e
     * @private
     */
    Ws.prototype._onError = function(e) {
        console.log(e);
    };

    /**
     * @method _onClose
     * @param {Object} e
     * @private
     */
    Ws.prototype._onClose = function(e) {
        console.log(e);
        //try to reco?
        if (this.maxTry > this.recoTry) {
            return;
        }
        this.socket = new WebSocket(this.url);
        this.init();
        this.recoTry++;
    };

    /**
     * Send stringify & send message to the socket
     * @method sendMessage
     * @param message
     */
    Ws.prototype.sendMessage = function(message) {
        message = JSON.stringify(message);
        this.socket.send(message);
    };

    /**
     * @class PlayerControl
     */
    var PlayerControl = function(options) {
        options = options || {};
        if (!options.socket instanceof Ws)
            throw "You need to provide a socket instance";

        if (!options.element || !options.element.length)
            throw "Element not found";

        this._playing = false;
        this._vClicked = false;
        this._progDragged = false;
        this._progClicked = false;
        this.element = options.element;
        this.socket = options.socket;
        this.duration = 7200;
        this.currentTime = 0;
        this.volume = 0.5;
        this._previousVolume = 1;
        this.timeInterval = null;
        this.enableInterval = false;
    };

    /**
     * @method init
     */
    PlayerControl.prototype.init = function() {
        //Add event listener
        var self = this;
        //Update time
        self.updateTime();
        var buttonHeight = self.element.find('.volume-button').height();
        var y = buttonHeight * this.volume * 10;
        self.updateVolume(y);
        var progWidth = this.element.find('.progress').width();
        var x = (progWidth / self.duration) * self.currentTime;
        self.updateProgress(x);

        $(window).bind('mouseup', function(e) {
            self._progClicked = false;
            self._progDragged = false;
            self._vClicked = false;
            self._dragVolume = false;
        });

        // Shortcuts
        $(window).bind('keydown', function(e) {
            switch (e.which) {
                case 32:
                    e.preventDefault();
                    self.playPause();
                    break;
                case 37: // left
                    var time = self.currentTime - (self.duration / 100);
                    self.seekTo(true, time);
                    break;

                case 39: // right
                    var time = self.currentTime + (self.duration / 100);
                    self.seekTo(true, time);
                    break;

                case 38: // up
                    e.preventDefault();
                    var buttonHeight = self.element.find('.volume-button').height();
                    var y = buttonHeight * (self.volume + 0.1) * 10;
                    self.updateVolume(y);
                    break;

                case 40: // down
                    e.preventDefault();
                    var buttonHeight = self.element.find('.volume-button').height();
                    var y = buttonHeight * (self.volume - 0.1) * 10;
                    self.updateVolume(y);
                    break;

                default:
                    return; // exit this handler for other keys
            }

        });

        this.element.find('.play-pause').bind('click', function() {
            self.playPause();
        });

        this.element.find('.progress').bind('mousedown', function(e) {
            self.mousedownProgress(e);
        });

        this.element.bind('mousemove', function(e) {
            if (self._progClicked) {
                self.dragProgress(e);
            }
            if (self._vClicked) {
                self.dragVolume(e);
            }
        });

        this.element.find('.volume-bar-holder').bind('mousedown', function(e) {
            self._vClicked = true;
            var y = self.element.find('.volume-bar-holder').height() - (e.pageY - self.element.find('.volume-bar-holder').offset().top);
            self.updateVolume(y);
        });

        this.element.find('.volume-icon').bind('mousedown', function() {
            if (self.volume) {
                self._previousVolume = self.volume;
                self.volume = 0;
            } else {
                self.volume = self._previousVolume;
            }
            var buttonHeight = self.element.find('.volume-button').height();
            var y = buttonHeight * self.volume * 10;
            self.updateVolume(y);
        });

    };

    /**
     * @method updateVolume
     * @param {number} y
     */
    PlayerControl.prototype.updateVolume = function(y) {
        var buttonHeight = this.element.find('.volume-button').height();
        var barHolderHeight = this.element.find('.volume-bar-holder').height();
        if (y > barHolderHeight) {
            y = barHolderHeight;
        }
        this.element.find('.volume-bar').css({
            height: y + 'px'
        });
        //between 1 and 0
        this.volume = this.element.find('.volume-bar').height() / barHolderHeight;
        this.animateVolume();
    };

    /**
     * @method playPause
     */
    PlayerControl.prototype.playPause = function() {
        if (this.isEnded()) {
            return this.pause();
        }

        if (this._playing) {
            this.pause(true);
        }
        else {
            this.play(true);
        }
    };

    /**
     * @method animateVolume
     */
    PlayerControl.prototype.animateVolume = function() {
        var volumeIcon = this.element.find('.volume-icon');
        volumeIcon.removeClass().addClass('volume-icon v-change-' + parseInt(this.volume * 10));
    };

    /**
     * @method getMouseProgressPosition
     * @param {Object} e - DOM event
     * @returns {number}
     */
    PlayerControl.prototype.getMouseProgressPosition = function(e) {
        return e.pageX - this.element.find('.progress').offset().left;
    };

    /**
     * @method mousedownProgress
     * @param {Object} e - DOM event
     */
    PlayerControl.prototype.mousedownProgress = function(e) {
        var progWidth = this.element.find('.progress').width();
        this._progClicked = true;
        var x = this.getMouseProgressPosition(e);

        this.currentTime = Math.round((x / progWidth) * this.duration);
        this.seekTo(true, this.currentTime);
    };

    /**
     * @method dragProgress
     * @param {Object} e - DOM event
     */
    PlayerControl.prototype.dragProgress = function(e) {
        this._progDragged = true;
        var progMove = 0;
        var x = this.getMouseProgressPosition(e);
        var progWidth = this.element.find('.progress').width();
        if (this._playing && (this.currentTime < this.duration)) {
            this.play();
        }
        if (x <= 0) {
            progMove = 0;
            this.currentTime = 0;
        }
        else if (x > progWidth) {
            this.currentTime = this.duration;
            progMove = progWidth;
        }
        else {
            progMove = x;
            this.currentTime = Math.round((x / progWidth) * this.duration);
        }
        this.seekTo(true, this.currentTime);
    };

    /**
     * @method dragVolume
     * @param {Object} e - DOM event
     */
    PlayerControl.prototype.dragVolume = function(e) {
        this._dragVolume = true;
        var volHeight = this.element.find('.volume-bar-holder').height();
        var y = volHeight - (e.pageY - this.element.find('.volume-bar-holder').offset().top);
        var volMove = 0;
        if (y <= 0) {
            volMove = 0;
        } else if (y > this.element.find('.volume-bar-holder').height() ||
            (y / volHeight) === 1) {
            volMove = volHeight;
        } else {
            volMove = y;
        }
        this.updateVolume(volMove);
    };

    /**
     * @method updateTime
     * @param {number} currentTime
     */
    PlayerControl.prototype.updateTime = function(currentTime) {
        var progWidth = this.element.find('.progress').width();
        currentTime = currentTime ||
        Math.round(($('.progress-bar').width() / progWidth) * this.duration);
        currentTime /= 1000;
        var duration = this.duration / 1000;
        var seconds = 0,
            minutes = Math.floor(currentTime / 60),
            tminutes = Math.round(duration / 60),
            tseconds = Math.round((duration) - (tminutes * 60));


        seconds = Math.round(currentTime) - (60 * minutes);

        if (seconds > 59) {
            seconds = Math.round(currentTime) - (60 * minutes);
            if (seconds === 60) {
                minutes = Math.round(currentTime / 60);
                seconds = 0;
            }
        }

        // Set a zero before the number if less than 10.
        if (seconds < 10) {
            seconds = '0' + seconds;
        }
        if (tseconds < 10) {
            tseconds = '0' + tseconds;
        }

        this.element.find('.ctime').html(minutes + ':' + seconds);
        this.element.find('.ttime').html(tminutes + ':' + tseconds);
    };

    /**
     * @method updateProgress
     * @param {number} x
     */
    PlayerControl.prototype.updateProgress = function(x) {
        var buttonWidth = this.element.find('.progress-button').width();

        this.element.find('.progress-bar').css({
            width: x
        });

        this.element.find('.progress-button').css({
            left: x - (2 * buttonWidth) - (buttonWidth / 2) + 'px'
        });
    };

    /**
     * @method isEnded
     * @returns {boolean}
     */
    PlayerControl.prototype.isEnded = function() {
        return this.currentTime >= this.duration;
    };

    /**
     * @method play
     * @param {boolean} send
     */
    PlayerControl.prototype.play = function(send) {
        var self = this;
        var progWidth = this.element.find('.progress').width();
        var delay = 1000;
        if (this.timeInterval) {
            clearInterval(this.timeInterval);
        }
        //@TODO: use requestFrame instead

        this._playing = true;
        this.element
            .find('.play-pause')
            .addClass('pause')
            .removeClass('play');

        if (send) {
            this.socket.sendMessage({
                type: 'pause'
            });
        }

        if (!this.enableInterval) {
            return;
        }
        this.timeInterval = setInterval(function() {
            if (self.isEnded()) {
                self.currentTime = self.duration;
                self.pause();
                return clearInterval(this.timeInterval);
            }
            self.currentTime += 1;
            self.updateTime(self.currentTime);
            var x = (progWidth / self.duration) * self.currentTime;
            self.updateProgress(x);
        }, delay);
    };

    /**
     * @method pause
     * @param {boolean} send
     */
    PlayerControl.prototype.pause = function(send) {
        if (this.timeInterval) {
            clearInterval(this.timeInterval);
        }

        this._playing = false;
        this.element
            .find('.play-pause')
            .addClass('play')
            .removeClass('pause');

        if (send) {
            this.socket.sendMessage({
                type: 'pause',
                currentTime: this.currentTime,
                media: {
                    id: this.id
                }
            });
        }
    };

    /**
     * @method seekTo
     * @param {boolean} send
     * @param {number} time
     */
    PlayerControl.prototype.seekTo = function(send, time) {
        //@TODO: make a debounce when dragging & key
        var progWidth = this.element.find('.progress').width();

        if (time < 0) {
            time = 0;
        }
        if (time > this.duration) {
            time = this.duration;
        }

        this.currentTime = time;

        if (this._playing) {
            this.play();
        }

        var x = (progWidth / this.duration) * this.currentTime;
        this.updateProgress(x);
        this.updateTime(this.currentTime);
        if (send) {
            this.socket.sendMessage({
                type: 'seekTo',
                currentTime: time
            });
        }
    };

    /**
     * @method goTo
     * @param {boolean} send
     */
    PlayerControl.prototype.goTo = function(send) {
        this.socket.sendMessage({
            type: 'goTo'
        });
    };

    /**
     * @method playing
     * @param {Object} message
     */
    PlayerControl.prototype.playing = function(message) {
        this.currentTime = message.currentTime;
        this.duration = message.media.duration;
        this.title = message.media.title;
        this.id = message.media.id;
        var titleElement = this.element.find('.title');
        titleElement.text(this.title);
        this.play();
    }

    /**
     * Instanciation of the Ws class
     */
    //@TODO: This URL need to be updated at runtime
    var URL = 'ws://192.168.0.14:8888';

    var socket = new Ws({
        url: URL
    });
    socket.init();

    var playerControl = new PlayerControl({
        socket: socket,
        element: $('.player-control')
    });
    playerControl.init();

    /**
     * Map which method is allowed by event type
     */
    var TYPE_MAP = {
        play: function(message) {
            playerControl.play(message);
        },
        pause: function(message) {
            playerControl.pause(message);
        },
        playing: function(message) {
            playerControl.playing(message);
        },
        seekTo: function(message) {
            playerControl.seekTo(null, message.currentTime);
        }
    };

    /**
     * Manage incoming messages
     */
    socket.onMessageCallbacks.push(function(message) {
        var key = 'type';
        var type = message[key];
        if (!type || typeof TYPE_MAP[type] !== 'function')
            return;
        TYPE_MAP[type](message);
    });

});
