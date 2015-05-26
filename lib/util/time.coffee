weekdays = [
    'Sun'
    'Mon'
    'Tue'
    'Wed'
    'Thu'
    'Fri'
    'Sat'
]

months = [
    'Jan'
    'Feb'
    'Mar'
    'Apr'
    'May'
    'Jun'
    'Jul'
    'Aug'
    'Sep'
    'Oct'
    'Nov'
    'Dec'
]

module.exports = (input) ->
    now = new Date()
    minutes =
        if now.getMinutes() < 10
            '0' + now.getMinutes()
        else
            '' + now.getMinutes()
    seconds =
        if now.getSeconds() < 10
            '0' + now.getSeconds()
        else
            '' + now.getSeconds()
    switch input
        when '\\d'
            "#{weekdays[now.getDay()]} #{months[now.getMonth()]} #{now.getDate()}"
        when '\\t'
            hours =
                if now.getHours() < 10
                    '0' + now.getHours()
                else
                    '' + now.getHours()
            "#{hours}:#{minutes}:#{seconds}"
        when '\\T'
            hours =
                if now.getHours() == 0
                    '12'
                else if now.getHours() < 10
                    '0' + now.getHours()
                else if now.getHours() < 13
                    '' + now.getHours()
                else if now.getHours() < 22
                    '0' + (now.getHours() - 12)
                else
                    '' + (now.getHours() - 12)
            "#{hours}:#{minutes}:#{seconds}"
        when '\\@'
            hours =
                if now.getHours() == 0
                    '12'
                else if now.getHours() < 10
                    '0' + now.getHours()
                else if now.getHours() < 13
                    '' + now.getHours()
                else if now.getHours() < 22
                    '0' + (now.getHours() - 12)
                else
                    '' + (now.getHours() - 12)
            suffix =
                if now.getHours() < 12
                    'AM'
                else
                    'PM'
            "#{hours}:#{minutes} #{suffix}"
        when '\\A'
            hours =
                if now.getHours() < 10
                    '0' + now.getHours()
                else
                    '' + now.getHours()
            suffix =
                if now.getHours() < 12
                    'AM'
                else
                    'PM'
            "#{hours}:#{minutes} #{suffix}"
        else
            throw new Error 'Invalid input [util/time]'
