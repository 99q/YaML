require 'date'

## initial users
users = []
ret = %x(bin/yaml user add -n 'dalang' -g 'male')
ret =~ /UUID \=\> (.+)/
users << $1

date = Date.new(1992, 10, 1).to_time.to_i
ret = %x(bin/yaml user add -n 'daisy' -g 'female' -b #{date})
ret =~ /UUID \=\> (.+)/
users << $1

date = Date.new(1990, 10, 1).to_time.to_i
ret = %x(bin/yaml user add -n 'jiangjun' -g 'male' -b #{date})
ret =~ /UUID \=\> (.+)/
users << $1

date = Date.new(1992, 10, 1).to_time.to_i
ret = %x(bin/yaml user add -n 'jdong' -g 'male' -b #{date})
ret =~ /UUID \=\> (.+)/
users << $1

date = Date.new(1991, 10, 1).to_time.to_i
ret = %x(bin/yaml user add -n 'lyg' -g 'male' -b #{date})
ret =~ /UUID \=\> (.+)/
users << $1

## initial points
points = []
data4points = {
  'dfmz' => ['dongfangmingzhu', 'modern' , '100,200'],
  'jmds' => ['jinmaodasha', 'modern' , '200,200'],
  'jrzx' => ['jinrongzhongxin', 'modern' , '200,300'],
  'wt' => ['waitan', 'modern' , '100,100'],
  'shbwg' => ['shanghaibowuguan', 'classic' , '1000,1000'],
  'lxgj' => ['luxunguju', 'classic' , '1200,900'],
  'ydhz' => ['yidahuizhi', 'classic' , '800,700'],
  'szh' => ['suzhouhe', 'classic' , '1000,1300'],
  'jjtb' => ['jiajiatangbao', 'food' , '10000,10000'],
  'xysj' => ['xiaoyangshengjian', 'food' , '800,9000'],
  'hall' => ['heianliaoli', 'food' , '5600,7200'],
  'flsj' => ['feilongshengjian', 'food' , '6600,5200'],
  'xdsk' => ['xiaodongshaokao', 'food' , '3600,1200'],
  'xtd' => ['xintangdong', 'food' , '15000,7900'],
  'b1' => ['fuquanB1', 'food' , '15000,8100'],
}

data4points.each do
  |name, point|
  ret = %x(bin/yaml point add -n #{name} -d #{point[0]} -t #{point[1]} -g #{point[2]})
  ret =~ /UUID \=\> (.+)/
  points << $1
end

## initial routes
routes = []
data4route = {
  'modern1'  => ['modern' , 3],
  'modern2'  => ['modern' , 2],
  'food1'    => ['food' , 4],
  'food2'    => ['food' , 6],
  'food3'    => ['food' , 7],
  'food4'    => ['food' , 2],
  'classic1' => ['classic' , 3],
}

data4route.each do
  |name, route|
  description = name
  number = route[1]
  point_array = []
  points.each do
    |uuid|
    ret = %x(bin/yaml point #{uuid})
    ret =~ /Type \=\> (.+)/
    if $1.strip == route[0]
      break if point_array.size == route[1]
      point_array << uuid.strip
    end
  end
  ret = %x(bin/yaml route add -n #{name} -d #{description} -t #{route[0]} -p #{point_array.join(',')})
  ret =~ /UUID \=\> (.+)/
  routes << $1
end

## initial YaML
yamls = []
data4yaml = {
  users[0] => [routes[1], routes[2]],
  users[1] => [routes[5], routes[3]],
  users[2] => routes[4],
  users[3] => [routes[4], routes[4], routes[1], routes[6]],
  users[4] => [routes[2], routes[2], routes[2]],
}

data4yaml.each do
  |user_uuid, route_arrays|
  route_arrays = Array(route_arrays)
  route_arrays.each do
    |route_uuid|
    ret = %x(bin/yaml yaml add -u #{user_uuid} -r #{route_uuid})
    ret =~ /UUID \=\> (.+)/
    yamls << $1
  end
end

## initial actions
yamls.slice(0, yamls.size - 3).each do
  |uuid|
  ret = %x(bin/yaml yaml update #{uuid} -c passport)
end
