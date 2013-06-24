(function() {
    "use strict";
    var Mosh = {
        Collections: {},
        Models:      {},
        Routers:     {},
        Views:       {}
    };

    // Helper functions to make Mustache templates McEasy
    Mosh.template = function(name) {
        return Mustache.compile($('#template-'+name).html());
    };

    Mosh.Models.CodeMosh = Backbone.Model.extend({
        urlRoot: '/mosh',
        initialize: function(options) {
            this.id = options.id;
        },
    });
    Mosh.Collections.LatestMoshes = Backbone.Collection.extend({
        model: Mosh.Models.CodeMosh,
        url: '/mosh/recent',
        initialize: function(options) {
            this.on('latestMosh:update', this.fetch,this);
            this.fetch();
        },
    });

    Mosh.Views.Mosh = Backbone.View.extend({
        template: Mosh.template('mosh'),
        render: function() {
            window.document.title
                = this.model.attributes.subject + ' - SpinalTapCodeMosh';
            this.$el.html( this.template( this.model.attributes ) );
            var classString = 'brush: ' + this.model.attributes.syntax;
            this.$el.find('pre').addClass(classString);
            return this;
        },
    });
    Mosh.Views.NewMosh = Backbone.View.extend({
        template: Mosh.template('new-mosh'),
        windowTitle: 'SpinalTapCodeMosh - Collaborative code paste binning.',
        render: function() {
            window.document.title = this.windowTitle;
            this.$el.html( this.template(this) );
            this.$el.find('form').validate({
                rules: {
                    subject: { required: 1 },
                    data:    { required: 1 },
                },
                messages: {
                    subject: {
                        required: 'You need to title this Mosh',
                    },
                    data: {
                        required: 'You need something in the Pit to Mosh with!',
                    },
                },
                submitHandler: function(form) {
                    $(form).submit(function(e) { e.preventDefault(); });
                    var button = $(form).find('button');
                    button.button('loading');
                    $.ajax({
                        type: 'POST',
                        url:  '/mosh',
                        data: {
                            subject: $(form.subject).val(),
                            data:    $(form.data).val() || 'None',
                            poster:  $(form.poster).val() || 'Guest',
                            syntax:  $(form.syntax).val(),
                        },
                        success: function(data) {
                            button.removeClass('btn-success btn-danger')
                                  .addClass('btn-success');
                            button.button('complete');
                            Mosh.router.navigate(
                                '/'+data.mosh.id,
                                { trigger: true }
                            );
                            Mosh.router.latestMoshCollection.trigger('latestMosh:update');
                        },
                        error: function() {
                            button.removeClass('btn-success btn-danger')
                                  .addClass('btn-danger');
                            button.button('error');
                        },
                    });
                    return false;
                },
            });
            return this;
        },
    });
    Mosh.Views.LatestMosh = Backbone.View.extend({
        tagName: 'li',
        template: Mosh.template('latest-mosh-item'),
        render: function() {
            this.model.attributes.age
                = moment( this.model.attributes.created ).fromNow();
            this.$el.html( this.template( this.model.attributes ) );
            return this;
        },
    });
    Mosh.Views.LatestMoshes = Backbone.View.extend({
        initialize: function(options) {
            this.listenTo(this.collection, 'all', this.render);
        },
        render: function() {
            this.$el.empty();
            this.collection.forEach(function(mosh) {
                var latestMoshView = new Mosh.Views.LatestMosh({ model: mosh });
                this.$el.append( latestMoshView.render().el );
            }, this);
            return this;
        },
    });

    // Controller, AKA the app Router
    Mosh.Routers.MoshPit = Backbone.Router.extend({
        initialize: function(options) {
            this.el = options.el;

            // We need to populate the latest moshes pane
            this.latestMoshCollection = new Mosh.Collections.LatestMoshes;
            this.latestMoshes = new Mosh.Views.LatestMoshes({
                el: $(this.el).find('#latest-mosh-list'),
                collection: this.latestMoshCollection,
            });
        },
        routes: {
            "":    "newMosh",
            ":id": "showMosh",
        },
        newMosh: function() {
            var newMosh = new Mosh.Views.NewMosh;
            this.updateMoshPit(newMosh);
        },
        showMosh: function(id) {
            var moshModel = new Mosh.Models.CodeMosh({ "id": id });
            moshModel.fetch({
                success: function() {
                    var moshView = new Mosh.Views.Mosh({ model: moshModel });
                    Mosh.router.updateMoshPit(moshView);
                },
                error: function() {
                    Mosh.router.navigate('/notfound');
                },
            });
        },
        updateMoshPit: function(moshView) {
            var moshPit = $(this.el).find('#moshpit');
            moshPit.fadeOut('fast', function() {
                moshPit.empty().append(moshView.render().el);
                SyntaxHighlighter.highlight();
                moshPit.fadeIn('fast');
            });

            // Also update the latest list.
            this.latestMoshCollection.trigger('latestMosh:update');
        },
    });

    // This is where the wind-milling starts
    Mosh.jumpIn = function(container) {
        container = $(container);
        var router = new Mosh.Routers.MoshPit({ el: container });
        Backbone.history.start({
            pushState: true,
        });

        // Handle AllTheLinks. Standard Backbone boiler-plate type stuff...
        $(document).on('click', 'a:not([data-bypass])', function(e) {
            var href     = $(this).attr('href');
            var protocol = this.protocol + '//';
            if (href.slice(protocol.length) !== protocol) {
                e.preventDefault();
                router.navigate(href, true);
            }
        });

        // Allow us to navigate from any of the views etc. (Slightly hacky)
        Mosh.router = router;
    };

    window.Mosh = Mosh;
    SyntaxHighlighter.defaults['toolbar'] = false;

})();

