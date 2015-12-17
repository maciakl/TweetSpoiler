$("#spoilerform").submit(function() {
  
    var source = spoiler = tweet = false;

    if($('#for').val()=="")
    {
        $('#foralert').slideDown();
        source = false;
    }
    else
    {
        $('#foralert').slideUp();
        source = true;
    }
    
    if($('#spoiler').val()=="")
    {
        $('#spoileralert').slideDown();
        spoiler = false;
    }
    else
    {
        $('#spoileralert').slideUp();
        spoiler = true;
    }
    

    if($('#tweet').val()=="")
    {
        $('#tweetalert').slideDown();
        tweet = false;
    }
    else
    {
        $('#tweetalert').slideUp();
        tweet = true;
    }


    return source && spoiler && tweet;
});


var max_count = 117 //maximum count 140 char minus 22 char for url shortener

$('#tweet').focus(function(){
  $(document).keyup(function(){
      
      var char_count = $('#tweet').val().length;
      var remaining_char = max_count - char_count;
      
      if (char_count < max_count) {
        $('#count').removeClass('red_text')
        .addClass('green_text')
        .text(' remaining '+remaining_char);
      } else {
        $('#count').removeClass('green_text')
        .addClass('red_text')
        .text(remaining_char);
      }
  });
});
