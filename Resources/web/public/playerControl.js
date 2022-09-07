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
    Ws.prototype.init = function(fn) {
        var self = this;
        this.init = true;
        this.socket.onopen = function() {
            self._onOpen(this);
            if (self.init && typeof fn === 'function') {
                //Should be called only once
                fn(this);
            }
            self.init = false;
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
        this.duration = 0;
        this.currentTime = 0;
        this.volume = 0.5;
        this._previousVolume = 1;
        this.timeInterval = null;
        this.enableInterval = false;
        this.volumeStyleMap = {
            0: 'mute',
            1: 'very-low',
            2: 'very-low',
            3: 'low',
            4: 'low',
            5: 'medium',
            6: 'medium',
            7: 'high',
            8: 'high',
            9: 'very-high',
            10: 'very-high'
        };
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
        var x = self.duration ? (progWidth / self.duration) * self.currentTime : 0;
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
                    self.seekTo({
                        send: true,
                        currentTime: time
                    });
                    break;

                case 39: // right
                    var time = self.currentTime + (self.duration / 100);
                    self.seekTo({
                        send: true,
                        currentTime: time
                    });
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
            this.pause({
                send: true
            });
        }
        else {
            this.play({
                send: true
            });
        }
    };

    /**
     * @method animateVolume
     */
    PlayerControl.prototype.animateVolume = function() {
        var volumeIcon = this.element.find('.volume-icon');
        volumeIcon.removeClass().addClass('volume-icon v-' + this.volumeStyleMap[parseInt(this.volume * 10)]);
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
        this.seekTo({
            send: true,
            currentTime: this.currentTime
        });
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
        this.seekTo({
            send: true,
            currentTime: this.currentTime
        });
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

    PlayerControl.prototype.formatTime = function(ms) {
        var timeMatch = new Date(ms).toUTCString().match(/(\d\d:\d\d:\d\d)/);
        return timeMatch.length ? timeMatch[0].replace('00:', '') : '00:00';
    };

    /**
     * @method updateTime
     * @param {number} currentTime
     */
    PlayerControl.prototype.updateTime = function(currentTime) {
        var progWidth, cTime, tTime;
        progWidth = this.element.find('.progress').width();
        currentTime = currentTime ||
        Math.round(($('.progress-bar').width() / progWidth) * this.duration);
        cTime = this.formatTime(currentTime);
        tTime = this.formatTime(this.duration);
        this.element.find('.ctime').text(cTime);
        this.element.find('.ttime').text(tTime);
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
    PlayerControl.prototype.play = function(options) {
        options = options || {};
        var self = this,
            send = options.send,
            currentTime = options.currentTime,
            delay = 1000,
            progWidth = this.element.find('.progress').width();

        //update currentTime
        this.currentTime = typeof currentTime !== 'undefined' ? currentTime : this.currentTime;

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
    PlayerControl.prototype.pause = function(options) {
        options = options || {};
        var send = options.send,
            currentTime = options.currentTime;
        //update currentTime
        this.currentTime = typeof currentTime !== 'undefined' ? currentTime : this.currentTime;

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
    PlayerControl.prototype.seekTo = function(options) {
        options = options || {};
        var currentTime = options.currentTime,
            send = options.send;

        //@TODO: make a debounce when dragging & key
        var progWidth = this.element.find('.progress').width();

        if (currentTime < 0) {
            currentTime = 0;
        }
        if (currentTime > this.duration) {
            currentTime = this.duration;
        }

        this.currentTime = currentTime;

        if (this._playing) {
            this.play();
        }

        var x = (progWidth / this.duration) * this.currentTime;
        this.updateProgress(x);
        this.updateTime(this.currentTime);
        if (send) {
            this.socket.sendMessage({
                type: 'seekTo',
                currentTime: currentTime
            });
        }
    };

    /**
     * @method getPlaying
     */
    PlayerControl.prototype.getPlaying = function() {
        //Trigger playing event (from server)
        this.socket.sendMessage({
            type: 'playing'
        });
    };

    /**
     * @method playing
     * @param {Object} message
     */
    PlayerControl.prototype.playing = function(options) {
        if (!options) {
            return;
        }
        options = options || {};

        this.currentTime = options.currentTime;
        this.duration = options.duration;
        this.title = options.title;
        this.id = options.id;

        var titleElement = this.element.find('.title');
        titleElement.text(this.title);
        this.play();
    }

    PlayerControl.prototype.openURL = function(options) {
        options = options || {};
        this.socket.sendMessage({
            type: 'openURL',
            url: options.url
        });
    };

    /**
     * Instanciation of the Ws class
     */
    var URL = 'ws://' + location.host;

    var socket = new Ws({
        url: URL
    });

    var playerControl = new PlayerControl({
        socket: socket,
        element: $('.player-control')
    });

    playerControl.init();
    socket.init(function() {
        playerControl.getPlaying();
    });

    /**
     * Map which method is allowed by event type
     */
    var TYPE_MAP = {
        play: function(message) {
            playerControl.play({
                currentTime: message.currentTime
            });
        },
        pause: function(message) {
            playerControl.pause({
                currentTime: message.currentTime
            });
        },
        playing: function(message) {
            playerControl.playing({
                currentTime: message.currentTime,
                duration: message.media.duration,
                title: message.media.title,
                id: message.media.id
            });
        },
        seekTo: function(message) {
            playerControl.seekTo({
                currentTime: message.currentTime
            });
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

    $('form.open-url').on('submit', function(e) {
        e.preventDefault();
        var url = $(this).find('input').val();
        var localesURL = LOCALES ? (LOCALES.PLAYER_CONTROL ? LOCALES.PLAYER_CONTROL.URL : {}) : {};
        if (!url) {
            return displayMessage(localesURL.EMPTY);
        } else if (!isURL(url)) {
            return displayMessage(localesURL.NOT_VALID);
        }
        displayMessage(localesURL.SENT_SUCCESSFULLY);
        playerControl.openURL({
            url: url
        });
        //clear the form
        $(this).find('input').val('');
    });

    /**
     * Check if a given string is a URL
     * Regex from https://gist.github.com/searls/1033143
     * It should accept http(s) , rtsp, etc.
     * @param {string} str
     * @returns {boolean}
     */
    function isURL(str) {
        var p = /\b((?:(?:rtsp|https?):\/\/|www\d{0,3}[.]|[a-z0-9.\-]+[.][a-z]{2,4}\/)(?:[^\s()<>]+|\(([^\s()<>]+|(\([^\s()<>]+\)))*\))+(?:\(([^\s()<>]+|(\([^\s()<>]+\)))*\)|[^\s`!()\[\]{};:'".,<>?«»“”‘’]))/i;
        return p.test(str);
    }
    //Display message to the user
    var TIMEOUT = null;
    var DELAY = 5000;
    function displayMessage(message) {
        if (!message) {
            return;
        }
        $('.display-message').addClass('show');
        $('.display-message').text(message);
        if (TIMEOUT) {
            clearTimeout(TIMEOUT);
        }
        TIMEOUT = setTimeout(function() {
            clearMessage();
        }, DELAY);
    }

    function clearMessage() {
        if (TIMEOUT) {
            clearTimeout(TIMEOUT);
        }
        $('.display-message').removeClass('show');
    }

});
