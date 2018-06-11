use diagn::RcReport;
use util::FileServer;
use util::enable_windows_ansi_support;
use asm::BinaryOutput;
use asm::AssemblerState;
use std::io::stdout;
use getopts;


enum OutputFormat
{
	Binary,
	BinStr,
	HexStr,
	HexStr2,
	BinDump,
	HexDump
}


pub fn drive(args: &Vec<String>, fileserver: &mut FileServer) -> Result<(), ()>
{
	let opts = make_opts();
	
	let report = RcReport::new();
	
	let result = drive_inner(report.clone(), &opts, args, fileserver);
	
	if report.has_messages()
		{ println!(""); }
	
	enable_windows_ansi_support();
	report.print_all(&mut stdout(), fileserver);
	
	if let Err(show_usage) = result
	{
		if show_usage
			{ print_usage(&opts); }
	}
	
	result.map_err(|_| ())
}


fn drive_inner(report: RcReport, opts: &getopts::Options, args: &Vec<String>, fileserver: &mut FileServer) -> Result<(), bool>
{
	let matches = parse_opts(report.clone(), opts, args).map_err(|_| true)?;
	
	if matches.opt_present("h")
	{
		print_usage(&opts);
		return Ok(());
	}
	
	if matches.opt_present("v")
	{
		print_version();
		return Ok(());
	}
	
	let quiet = matches.opt_present("q");
	let out_stdout = matches.opt_present("p");
	
	let out_format = match matches.opt_str("f").as_ref().map(|s| s.as_ref())
	{
		Some("binstr")  => OutputFormat::BinStr,
		Some("bindump") => OutputFormat::BinDump,
		Some("hexstr")  => OutputFormat::HexStr,
		Some("hexstr2") => OutputFormat::HexStr2,
		Some("hexdump") => OutputFormat::HexDump,
		Some("binary")  => OutputFormat::Binary,
		
		None => if out_stdout
			{ OutputFormat::HexDump }
		else
			{ OutputFormat::Binary },
		
		Some(_) =>
		{
			report.error("invalid output format");
			return Err(true);
		}
	};
	
	if matches.free.len() < 1
		{ return Err(true); }
	
	let main_asm_file = matches.free[0].clone();
	
	let output_file = match matches.opt_str("o")
	{
		Some(f) => f,
		None =>
		{
			match get_default_output_filename(report.clone(), &main_asm_file)
			{
				Ok(f) => f,
				Err(_) => return Err(true)
			}
		}
	};
	
	let mut filenames = matches.opt_strs("i");
	for filename in matches.free
		{ filenames.push(filename); }
	
	let assembled = assemble(report.clone(), fileserver, &filenames, quiet).map_err(|_| false)?;
	
	let output_data = match out_format
	{
		OutputFormat::BinStr  => assembled.generate_binstr (0, assembled.len()).bytes().collect::<Vec<u8>>(),
		OutputFormat::BinDump => assembled.generate_bindump(0, assembled.len()).bytes().collect::<Vec<u8>>(),
		OutputFormat::HexStr  => assembled.generate_hexstr (0, assembled.len()).bytes().collect::<Vec<u8>>(),
		OutputFormat::HexStr2 => assembled.generate_hexstr2(0, assembled.len()).bytes().collect::<Vec<u8>>(),
		OutputFormat::HexDump => assembled.generate_hexdump(0, assembled.len()).bytes().collect::<Vec<u8>>(),
		OutputFormat::Binary  => assembled.generate_binary (0, assembled.len())
	};
	
	if out_stdout
	{
		if !quiet
		{
			println!("success");
			println!("");
		}
			
		println!("{}", String::from_utf8_lossy(&output_data));
	}
	else
	{
		println!("writing `{}`...", &output_file);
		fileserver.write_bytes(report.clone(), &output_file, &output_data, None).map_err(|_| false)?;
		
		if !quiet
			{ println!("success"); }
	}
	
	Ok(())
}


fn make_opts() -> getopts::Options
{
    let mut opts = getopts::Options::new();
    opts.optopt("f", "format", "The format of the output file. Possible formats: binary, binstr, hexstr, hexstr2, bindump, hexdump", "FORMAT");
    opts.optmulti("i", "include", "Specifies an additional file for processing before the given <asm-files>.", "FILE");
    opts.optopt("o", "output", "The name of the output file.", "FILE");
    opts.optflag("p", "print", "Print output to stdout instead of writing to a file.");
    opts.optflag("q", "quiet", "Suppress progress reports.");
    opts.optflag("v", "version", "Display version information.");
    opts.optflag("h", "help", "Display this information.");
	
	opts
}


fn parse_opts(report: RcReport, opts: &getopts::Options, args: &Vec<String>) -> Result<getopts::Matches, ()>
{
	match opts.parse(&args[1..])
	{
        Ok(m) => Ok(m),
        Err(f) => Err(report.error(format!("{}", f)))
    }
}


fn print_usage(opts: &getopts::Options)
{
	println!("{}", opts.usage(&format!("Usage: {} [options] <asm-file-1> ... <asm-file-N>", env!("CARGO_PKG_NAME"))));
}


fn print_version()
{
	println!("{} v{}", env!("CARGO_PKG_NAME"), env!("CARGO_PKG_VERSION"));
}


fn print_header()
{
	print_version();
}


fn get_default_output_filename(report: RcReport, input_filename: &str) -> Result<String, ()>
{
	use std::path::PathBuf;
	
	let mut output_filename = PathBuf::from(input_filename);
	output_filename.set_extension("bin");
	
	let output_filename = output_filename.to_string_lossy().into_owned().replace("\\", "/");
	
	if output_filename == input_filename
		{ return Err(report.error("cannot derive safe output filename")); }
	
	Ok(output_filename)
}


pub fn assemble(report: RcReport, fileserver: &FileServer, filenames: &[String], quiet: bool) -> Result<BinaryOutput, ()>
{
	if !quiet
		{ print_header(); }
	
	let mut asm = AssemblerState::new();
	
	for filename in filenames
	{
		let filename_owned = filename.clone();
		
		if !quiet
			{ println!("assembling `{}`...", &filename_owned); }
	
		asm.process_file(report.clone(), fileserver, filename_owned)?;
	}
	
	asm.wrapup(report)?;
	Ok(asm.get_binary_output())
}