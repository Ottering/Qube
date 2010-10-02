require 'qube'

Qube.import_config('bin/qube.rbo')

app = Qube::RenderWindow.new(
		QENV['wv_title'],	# title of window
		QENV['wv_size'],	# size of window
		QENV['wv_pos']		# position of window
	)
app.create()
app.mainloop()
