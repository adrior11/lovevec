htmlreport := luacov.report.html
reportfile := luacov.report.out
statsfile := luacov.stats.out

benches:
	@lua bench/vec_bench.lua
	@luajit bench/vec_bench.lua

codecov:
	@busted -c
	@luacov -r lcov

coverage:
	@busted -c
	@luacov
	@mv $(reportfile) $(htmlreport)

clean:
	@rm -rf $(reportfile) $(statsfile) $(htmlreport)
