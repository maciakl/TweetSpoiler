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
