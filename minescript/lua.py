
-- def run(python_code: str) -> None:
--   """Executes python_code as an expression or statements.

--   Args:
--     python_code: Python expression or statements (newline-delimited)
--   """
--   # Try to evaluate as an expression.
--   try:
--     print(builtins.eval(python_code), file=sys.stderr)
--     return
--   except SyntaxError:
--     pass

--   # Fall back to executing as statements.
--   builtins.exec(python_code)


-- if __name__ == "__main__":
--   if len(sys.argv) < 2:
--     print(
--         f"eval.py: Expected at least 1 parameter, instead got {len(sys.argv) - 1}: {sys.argv[1:]}",
--         file=sys.stderr)
--     print(r"Usage: \eval <pythonCode> [<line2> [<line3> ...]]", file=sys.stderr)
--     sys.exit(1)

--   run("\n".join(sys.argv[1:]))

local minescript = require("minescript")

local env = {}
setmetatable(env, {__index = function(t, k)
    return _G[k] or minescript[k]
end})

local function run(code)
    local ok, res = pcall(load, "return " .. code)
    if ok and res then
        setfenv(res, env)
        minescript.echo(res())
        return
    end
    assert(load(code))()
end

run(table.concat({unpack(arg, 3)}, "\n"))

os.exit()