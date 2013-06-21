(function() {
    "use strict";
    var Mosh = {
        Collections: {},
        Models:      {},
        Routers:     {},
        Views:       {}
    };

    Mosh.Collections.LatestMoshes = Backbone.Collections.extend({

        initialize: function(options) {
        },

    });

    //
    Mosh.Views.LatestMoshes = Backbone.Views.extend({
        initialize: function(options) {
            this.collection = new Most.Collections.LatestMoshes;
            _bind('change', this.render(), this);
        },
        render: function() {
            this.collection.forEach(function(model) {
                this.$el.append( model.render().el );
            });
        },
    });

    // Controller, AKA the app Router
    Mosh.Routers.MoshPit = Backbone.Router.extend({
        initialize: function(options) {

            // We need to populate the lastest moshes pane
            this.latestMoshes = new Mosh.Views.LatestMoshes({
                el: this.$el.find('#lastest-moshes')
            });
        };
        routes: {
            "":    "newMosh",
            ":id": "showMosh",
        },


       updateLatestMoshes: function() {
            this.latestMoshes.fetch(
                success: function(collection) {

                    collection.forEach(function(mosh) {
                        var lastestMoshList = new Mosh.Views.LatestMoshes({ model: mosh });

                    router.$el.find('#latest-moshes').append
                },
                error: function() {

                },
            );
        },
    });



    // Helper function to make Mustache templates McEasy
    Mosh.template = function(name) {
        return Mustache.compile($('#template-'+name).html());
    };

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
    };
})();

