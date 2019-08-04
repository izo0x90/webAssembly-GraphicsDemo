var gulp = require("gulp"),
	exec = require("child_process").exec,
	connect = require("gulp-connect");

gulp.task("buildWasm", async function(cb) {
	exec("node build.js", function(err, stdout, stderr) {
		console.log(stdout);
		console.log(stderr);
		cb(err);
	});
});

gulp.task("copyStatic", async function() {
	gulp.src("src/*.{html,js}").pipe(gulp.dest("out"));
});

gulp.task("server", async function() {
	connect.server({ root: [".", "out"] });
});

gulp.task("buildAll", gulp.series("buildWasm", "copyStatic"));

gulp.task("default", gulp.series("buildAll", "server"));
