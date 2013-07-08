'use strict';

module.exports = function(grunt) {
    grunt.initConfig({
        coffee: {
            glob_to_multiple: {
                expand: true,
                flatten: true,
                src: "coffee/*.coffee",
                dest: "player/",
                ext: ".js"
            }
        },

        watch: {
            coffee: {
                files: 'coffee/*.coffee',
                tasks: ['coffee']
            }
        }
    });

    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-watch');
};
