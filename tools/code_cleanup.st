/*
 * This tool will automatically detect the start of top-level class definitions and will redirect them to
 * the proper output .dm file for each class path. The tool should be run from the base directory with
 * the .dme file as follows with FILEPATH replaced with the input file one wishes to cleanup.
 *
 * states -s default -f tools/code_cleanup.st < FILEPATH.dm | sh
 *
 * The output will be a shell script with multiple "here documents" that when executed, will append the
 * various class definitions to the proper output files. In practice, one should examine the output of the
 * shell script and make any manual corrections as needed.
 *
 * This tool is written for the "states" command which is part of GNU Enscript. This mini-language is
 * similar to awk, but the regex patterns can match anywhere, unlike the line oriented nature of awk.
 * Essentially, it's a scripted lexical analyzer.
 */

/* Regular expression to detect a class/proc/var top-level definition and extract the type name */
type_regex = /^\/?([a-zA-Z0-9_][a-zA-Z0-9_\/]*\(?)/;

/* Comment blocks and file header are saved here temporarily so they can be later sent to another file */
saved_text = "";

/* If true, output to a file has begun and it's no longer necessary to save all input in saved_text */
output = "";

/* Detected end of line format; needed when printing the final "here document" delimiter */
eol = "\n";

/* Delimiter to mark the end of each shell "here document" in the output */
delim_print = "######################################################################";
delim_regex = /######################################################################/;

state default
{
	/* Safety check to make sure input doesn't already contain the "here document" delimiter */
	delim_regex { panic("!!! SHELL CODE INJECTION DETECTED !!!"); }

	/\/\*/      { save($0); call(block_comment); }
	/\{\"/      { dump($0); call(block_string); }
	/\"/        { dump($0); call(inline_string); }
	/\/\//      { save($0); call(inline_comment); }
	/\r\n/      { dump($0); eol = $0; }
	/./         { dump($0); }

	/* Any filepath like definition at the start of a line begins a new file */
	type_regex {
		text = $0;
		type_name = $1;

		/* Safety check to make sure input doesn't already contain the "here document" delimiter */
		if(regmatch(text, delim_regex)) {
			panic("!!! SHELL CODE INJECTION DETECTED !!!");
		}

		/* Isolate the typename and its base directory which will hold the output file */
		type_name = regsub(type_name, /\/(var|proc|verb).*($|\n)/, "");
		type_name = regsub(type_name, /\/[a-zA-Z0-9_]+\(/, "");

		/* Check for global proc definitions which go into code/proc.dm */
		if(regmatch(type_name, /^\/?proc/)) {
			type_name = "proc";
		}

		/* Check for const var definitions which go into code/var/const.dm as an indented block */
		else if(regmatch(type_name, /^var\/const\//)) {
			type_name = "var/const";
			text = regsub(text, /^\/?var\/const\//, "\t");
		}

		/* Check for global var definitions which go into code/var/global.dm as an indented block */
		else if(regmatch(type_name, /^var(\/global)?\//)) {
			type_name = "var/global";
			text = regsub(text, /^\/?var(\/global)?\//, "\t");
		}

		/* Only start a new output file if if is different from the current output file or it's the first one */
		if(strcmp(output, type_name) != 0) {
			/* If file output has already started, terminate the previous shell "here document" */
			if(length(output)) {
				print(delim_print, "\n");
			}
			output = type_name;

			/* Create destination directory and start a new shell "here document" that redirects to output file */
			base_name = regsub(type_name, /(^|\/)[a-zA-Z0-9_]+($|\n)/, "");
			print("mkdir -p code/", base_name, "\n");

			print("cat >> code/", type_name, ".dm <<\\\n");
			print("\"", delim_print, "\"\n");
		}

		/* Print out any previous comment blocks followed by this definition line to the output file */
		dump(text);
	}

	/* Triggered at the end of input to close the final "here document" if one is open */
	END {
		if(output) {
			print(eol, delim_print, "\n");
		}
	}
}

/*
 * Parse inline comments started with // and continuing until the end of the current line.
 * Comment blocks are temporarily saved so they can be redirected later to the proper file.
 */
state block_comment
{
	/* Safety check to make sure input doesn't already contain the "here document" delimiter */
	delim_regex     { panic("!!! SHELL CODE INJECTION DETECTED !!!"); }

	/\*\/ *\r?\n?/  { save($0); return; }
	/./             { save($0); }
}

/*
 * Parse inline comments started with // and continuing until the end of the current line.
 * Comment blocks are temporarily saved so they can be redirected later to the proper file.
 * Remaining whitespace on the same line as the closing comment delimiter is saved as if it
 * was part of the comment block. This allows immediatly adjacent comment blocks to group
 * together for the purposes of saving and redirecting them to the proper file.
 */
state inline_comment
{
	/* Safety check to make sure input doesn't already contain the "here document" delimiter */
	delim_regex    { panic("!!! SHELL CODE INJECTION DETECTED !!!"); }

	/\n/    { save($0); return; }
	/./     { save($0); }
}

/*
 * Parse block strings enclosed within {" and "}. End delimiters escaped with \"} are handled
 * and do not prematurely terminate the string block.
 */
state block_string
{
	/* Safety check to make sure input doesn't already contain the "here document" delimiter */
	delim_regex    { panic("!!! SHELL CODE INJECTION DETECTED !!!"); }

	/\\\"/  { dump($0); }
	/\"\}/  { dump($0); return; }
	/./     { dump($0); }
}

/*
 * Parse regular inline strings enclosed within " quotes. A double quote escaped with \" is
 * handled correctly and does not prematurely terminate the string.
 */
state inline_string
{
	/* Safety check to make sure input doesn't already contain the "here document" delimiter */
	delim_regex    { panic("!!! SHELL CODE INJECTION DETECTED !!!"); }

	/\\\"/  { dump($0); }
	/\"/    { dump($0); return; }
	/./     { dump($0); }
}

/*
 * Save a piece of text for later printing with dump(). Used to delay the immediate output of
 * comment blocks so they can be redirected later to the proper output file once a top-level
 * type declaration was found.
 */
sub save(text)
{
	saved_text = concat(saved_text, text);
}

/*
 * Print out and forget any previously saved text with save(), followed by immediately printing
 * out the text passed into this function as an argument. However, if the output file is not
 * known yet because no top-level type declaration has been found, then this function just calls
 * save() to preserve the entire file header until it can be redirected to the first output
 * file found.
 */
sub dump(text)
{
	if(length(output)) {
		print(saved_text, text);
		saved_text = "";
	} else {
		save(text);
	}
}
