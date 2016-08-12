
function sleep(milliseconds) {
  var start = new Date().getTime();
  for (var i = 0; i < 1e7; i++) {
    if ((new Date().getTime() - start) > milliseconds){
      break;
    }
  }
}


// once document is loaded
$( document ).ready(function() {

  // document width
  body_width = $("body").width();
  // column width from CSS
  column_width = 260;
  // using pos to guess width of actual content
  content_width = $("pre").position().left*2 + column_width;
  margin = (body_width - content_width)/2;

  // centering horizontally
  $(".b9").css("margin-left", margin);
  // reducing document width as much
  $("body").css("width", body_width-margin);

});
