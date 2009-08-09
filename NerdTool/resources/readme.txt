                                    NerdTool
                                     v 0.6
                                     Readme
                                   2009-08-05
Developer: Kevin Nygaard
Website: <http://balthamos.darkraver.net/>
Email: balthamos89 AT gmail DOT com
Source: <http://github.com/balthamos/geektool-3/tree/experimental>
================================================================================
Description
    NerdTool is a GeekTool-like application that displays information directly
    on your desktop. It has the capability of displaying text in any color,
    size, and font on any background of any color, and NerdTool supports the use
    of ANSI escape sequences to color text, so you can embellish your text with
    an additional 8 foreground and background colors. Additionally, NerdTool
    allows displaying images, websites, and even Quartz composer files directly
    on the desktop.

Usage
    You can run NerdTool from the application, but it will not run correctly or
    efficiently. To use NT for everyday use, check the `Enable NerdTool'
    checkbox, then simply quit the application. Once terminated, NT will start a
    smaller process that runs in the background that will display all your logs.

Interface
    The main NerdTool interface consists of two major parts: the log selector
    and the log editor. A `log' is simply an object that is displayed on your
    screen, and does not literally mean a log (but it could).

    Selector (Group)
        Logs are organized into groups, which make it easy to have multiple
        configurations of NerdTool. Only one group can be active at a time.
        In turn, each log has its own enabled status. When disabled, the log
        will not run or display on the screen. This makes it easy to enable
        customize your layout on the fly.

        The order in which the logs are drawn on the screen is directly related
        to the position on the table. Logs higher on the list are drawn last,
        and logs lower on the list are drawn first. This means that logs higher
        on the list will be higher than the one below it.

        Logs can (obviously) be reordered, duplicated, exported, imported, and
        created all through the table. Access to duplication and exportation
        features are available through the lower gear menu. NerdTool was
        developed to behave like a proper Apple application, so it took on an
        popular trait: cross-application compatibility. So, take any file from
        any application and drop it into the table, and NerdTool should find out
        what to do with it if it can. Drop an image, and NerdTool will make a
        new image log with the settings already filled out. Drag a URL from
        Safari and NerdTool will make a new web log. Additionally, you can drag
        a log out of the table and onto the desktop quickly export a log, and
        drag an exported log onto the table to import it quickly. And, in the
        spirit usefulness, you can select a bunch of files, be they images, text
        files, exported logs, or a mixture of all, throw them into the table,
        and NerdTool will automatically do what it can with each of the files.

    Editor (Log)
        On this side of the main screen, you will see a rather large blank
        portion, which displays settings unique to the log type, and generic log
        settings below that; a Display box for logs that use text, and a Window
        box that every log inherits, which holds information on where and how it
        is displayed.

        Display
            Encoding: The encoding that will be used to evaluate the output data.
            Alignment: Align text either left, center, right, or justified.
            Wrap output: Soft-wrap a line when it reaches the end of the window.
            Drop shadow: Display a drop shadow on the text.
            Colorize output: Evaluate color, intensity, and underline ANSI escape
               sequences. Colors can be customized via the `Customize' button.
            Background: The background color of the text.
            Text: The foreground color of the text.
            Font: Click to change the size and typeface of font.

        Window
            Shadow: Display a drop shadow on the log windows.
            Always on top: Instead of being below all windows, put the log above
                all other windows.
            Size to screen: Keep the size of the window the full size of the
                screen, even when the monitor resolution changes.
            x,y: Cartesian coordinates of the log window, in pixels. The location
                0,0 is in top-left corner of the screen and the origin of the window
                the top left corner.
            w,h: The width and height respectively of a log window in pixels.

        Shell
            Refresh: After this time (in seconds) elapses, the command will be
                run again and the log output flushed. Specifying a time of `0' will
                make the log fire once only, then never refresh again. Refreshing
                more often will use more resources. 
            Command: The command to execute. Input is basic /bin/sh, but you can
                call any script you like; just as if it were in the Terminal.app. To
                insert hard linebreaks, press Alt+Return or Ctrl+Return.
            Size window to fit: Resize the log window to perfectly fit the
                existing contents.
            Printing modes:
                See section ``Log Types'' for more information on usage.
                Wait for all data: Standard shell option. Wait until the entire
                    command is done before printing anything.
                Append new data: Start printing data as it comes, and append it
                    to the current buffer.
                Print new data only: When new data arrives, print that new data,
                    and only that new data (flush the old buffer).

        Image
            Refresh: Same as Shell.
            URL: The URL of the image can either be a local image (file://) or
                online (http://). Any valid URL will work.
            Alignment: The position the image will sit in the window.
            Scaling: What to do with the image when the window size is not equal
                to the image size
            Opacity: How opaque the image is. 0% is completely transparent.

        File
            Path: The standard path to the file you wish to monitor.
            Size window to fit: Same as Shell.

        Quartz
            Refresh: Same as Shell
            Path: The standard path to the Quartz file you wish to display.
            Framerate: When set to 1, the log is refreshed based on the value in
                the refresh box. When set to any value besides 1, the refresh time
                is ignored, instead, displaying the Quartz rendering at the
                specified framerate. Please note that rendering at a high fps takes
                lots of CPU time.

        Web
            Refresh: Same as Shell
            URL: Same as Image
            Opacity: Same as Image
            Save scroll location: This button must be pushed when you are
                finished with your scrolling. This saves the information about
                the location for when running after the application closes.

    Options
        Magnetize logs: logs will snap to a common axis. Useful for aligning
            logs nicely.
        Exposé border: display a region in which standard windows are pushed to.
            This way, when you push the Desktop Exposé button, your NerdTool
            logs will not be obscured by other windows.
        Lock size: lock the size of the log window. Useful for moving around
            logs to find the best placement after size has been chosen to
            prevent accidental resizing.

    Preferences
        Check for updates: check for updates occasionally and automatically
            update when present. Note, updates will only occur when the main
            application open, not the background process NerdToolRO (the one
            that spawns after `Enable NerdTool' has been checked).
        Open at login: make a login item for the background process NerdTool
            launches.
        Donate: open a web page where you could show some appreciation for a
            really cool guy :)
        Import GeekTool 2 logs: import logs from GeekTool2. Logs do not retain
            their enabled status, but otherwise are very similar.

Log Types
    There are many log types in NerdTool, and I will just give you a short
    description of them and where to go to find out more information on how to
    use them.

    Shell
        Executes a shell command and outputs the result to the window. Commands
        are sh, but can take any script that has execution privileges.
        When printing information as it comes (like `tail -F', what File logs
        use), it may be hard to get data to come out as you expect it too. In my
        tests, running a simple tail -F works with no trouble at all, but as
        soon as you start piping information around, things stop working.
        For example, 
            `tail -F aFile.txt | sed 's/old/new/'' 
        does not work. The problem seems to be with the buffering of the output.
        NerdTool likes the output to be line-buffered, so to do that with this
        command specifically, you could do
            `tail -F aFile.txt | sed -l 's/old/new/'' 
        which makes the output line buffered. I have successfully gotten outputs
        for the `Append new data' option for `sed', `grep', and `awk'. A quick
        search told me that experienced perl users should know what to do, and
        I'm guessing that other like languages have similar methods.
        For `sed' use the `-l' option.
        For `grep' use the `--line-buffered' option.
        For `awk' use `fflush()' where appropriate in your command.

        If you have more methods, or better instructions/explanations, for line
        buffering, please send them to me.
            
        Relevant topics:
            Shell script <http://en.wikipedia.org/wiki/Shell_script>
            Quick guide to bash
            <http://www.panix.com/~elflord/unix/bash-tute.html>
            Advanced bash scripting <http://tldp.org/LDP/abs/html/index.html>
            Colorizing scripts
            <http://www.faqs.org/docs/abs/HTML/colorizing.html>
            ANSI escape sequences
            <http://ascii-table.com/ansi-escape-sequences.php>

    Image
        Displays an image.
        Relevant topics:
            GIMP <http://www.gimp.org/>

    File
        Displays a file, and automatically updates when needed. Very efficient.
        Relevant topics:
            None

    Quartz
        Display a Quartz file.
        Relevant topics:
            Quartz Composer <http://en.wikipedia.org/wiki/Quartz_Composer>

    Web
        Display a website.  Just a few notes about this log type. 
        When this log updates, you may see the web page redraw itself (some
        elements of the page disappear and then reappear). This is normal
        operation.  
        Another thing is that the only way to resize scroll the page right now
        is via a mouse scroll wheel (or trackpad). I'm sure you know how to
        scroll vertically, but many do not know how to scroll horizontally. To
        scroll horizontally, simply hold Shift and scroll as you normally would
        (this works in many other applications as well).
        Also, when you are trying to scroll the window to the proper place, you
        may notice the scroll bars jumping up and then back down again. This
        happens when the page refreshes. It is recommended that you set the
        refresh rate to 0 temporarily to get everything set up properly, and
        then set it back when you are finished.
        Advanced web programmers will find it is easier just to leave the
        refresh rate at 0 and do their own programming on the website end, as
        NerdTool refreshs at a constant rate, whether the content has changed or
        not.
        Also, you cannot interface with the web page at all.
        Relevant topics:
            PHP <http://en.wikipedia.org/wiki/PHP>
            Ajax <http://en.wikipedia.org/wiki/Ajax_(programming)>
            jQuery <http://jquery.com/>

Additional Information
    NerdTool is free and open source, with the source code being located at
    GitHub (link at beginning of document). NerdTool's background process is
    known as NerdToolRO, and can be located in NerdTool.app/Contents/Resources/.
    If you want to make the application launch at startup, put this process in
    your startup items. It's also worth mentioning again that NerdTool will NOT
    automatically update in this process, only in the main NerdTool.app.

    Questions/comments/requests/complaints/insults/donations are all greatly
    appreciated.

Licensing/Advise/Legal
    If NerdTool explodes your computer, I take no responsibility for it. Since
    NerdTool executes shell scripts on your computer, it could be used to
    compromise/destroy your computer, especially with the advent of log
    import/export. Don't trust log files from anyone you don't trust, and don't
    use any command/script unless you know what it does.

    NerdTool is free software: you can redistribute it and/or modify it under
    the terms of the GNU General Public License as published by the Free
    Software Foundation, either version 3 of the License, or (at your option)
    any later version.

    NerdTool is distributed in the hope that it will be useful, but WITHOUT ANY
    WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
    FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
    details.

    You should have received a copy of the GNU General Public License along with
    NerdTool.  If not, see <http://www.gnu.org/licenses/>.
    
