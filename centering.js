
// once document is loaded
$( document ).ready(function() {
  // document width
  body_width = $("body").width()
  // using pos to guess width of actual content
  content_width = $("pre").position().left*2
  margin = (body_width - content_width)/2

  // centering horizontally
  $(".b9").css("margin-left", margin);
  // reducing document width as much
  $("body").css("width", body_width-margin);
});
