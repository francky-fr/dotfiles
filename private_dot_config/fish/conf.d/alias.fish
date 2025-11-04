function nv
	nvim $argv
end

function dbui
	nvim +DBUI $argv
end

function dbui_admin
	WITH_ADMIN_DB=1 nvim +DBUI $argv
end
