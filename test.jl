using Distributions
using Turing
using Plots
Plots.plotly()

# params (computed from empirical data)
LAMBDA = 0.6882627
ALPHA = 1.3441739239406807
SIGMA = 0.4203008


mutable struct Model
    post_list
    top_list
    tick
    n_users
end


mutable struct Post 
    id::Int64
    quality::Float64
    votes::Int64
    views::Int64
    timestamp::Int64
    score::Float64
end




function generate_attention(n) 
    pois = Poisson(10)
    return rand(pois, n)
end

# Wie legen wir n fest?
# Aus den Daten holen (wie viele Votes werde pro Minute abgegeben?)


# refactor
function user_interaction!(post_list, attention_list) 
    for att in attention_list
        for i in 1:att
            if i <= length(post_list)
                post_list[i].views += 1
                if rand(Uniform(0, 1)) < 0.001 * post_list[i].quality
                    post_list[i].votes += 1
                end
            else
                break
            end
        end
    end
    return post_list
end


function score_single(post, tick)
    age = (tick - post.timestamp) / 60
    votes = post.votes
    return ((votes - 1)^0.8)/((age + 2)^1.8)
end

function hnscore!(post_list, tick) 
    for p in post_list
        p.score = score_single(p, tick)
    end
    return post_list
end

# sort only first 1500
function sort_toplist(post_list)
    toplist = sort(post_list, rev=true, by=(post -> (post.score, post.votes)))
    return toplist
end


function bias_lambda(slice, alpha=ALPHA, sd=SIGMA)
    sd * (- alpha * sin(2 * pi  * slice))
end

function draw_arrival_rate(tick, ticks_per_day, arrival_rate_mean=LAMBDA; alpha=ALPHA, arrival_rate_sd=SIGMA)
    rel_slice = mod(tick, ticks_per_day)
    lambda = arrival_rate_mean + bias_lambda(rel_slice, alpha, arrival_rate_sd)
    dist = Poisson(lambda)
    return rand(dist)
end

# try using data for sampling


function tick!(model::Model)
    model.tick += 1
    # add new posts
    arrival_rate = draw_arrival_rate(model.tick, 1440)
    for i in 1:arrival_rate
        push!(
            model.post_list, 
            Post(
                length(model.post_list) + 1, 
                rand(Uniform(0, 1)),
                1, 
                0,
                model.tick,
                0.0
            )
        )
    end
    hnscore!(model.post_list, copy(model.tick))
    newest = length(model.post_list) >= 1500 ? model.post_list[1:1500] : model.post_list
    model.top_list = sort_toplist(newest)
    attention_top = generate_attention(10)
    attention_new = generate_attention(100)
    user_interaction!(model.top_list, attention_top)
    user_interaction!(model.post_list, attention_new)
    return model
end


model = Model([], [], 0, 10)

for i in 1:2880
    tick!(model)
end

for p in model.top_list[1:30]
    print(p, "\n")
end

model.post_list

l = [draw_arrival_rate(i, 1440) for i in 1:1440]
histogram(l)



post_list = [Post(i, rand(Uniform(0, 1)), 1, 0, 6, 1.0) for i in 1:100]
attention_list = generate_attention(100)
user_interaction!(post_list, attention_list)
hnscore!(post_list, 8)
toplist = sort_toplist(post_list)

post_list

# Wie ist Qualität verteilt?
# korreliert mit votes?
# baseline: wie schnell entwickeln sich Posts? -> "Steile" der Kurve
# mehr votes auf der front page -> mehr qualität?
# qualität nur proxy? 

# votes + age -> wie verhalten sie sich in Bezug auf score?

