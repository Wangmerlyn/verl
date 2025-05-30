set -x

gsm8k_train_path=$HOME/data/gsm8k/train.parquet
gsm8k_test_path=$HOME/data/gsm8k/test.parquet
math_train_path=$HOME/data/math/train.parquet
math_test_path=$HOME/data/math/test.parquet

train_files="['$gsm8k_train_path', '$math_train_path']"
test_files="['$gsm8k_test_path', '$math_test_path']"

# tested on L20-16 GPUs per nodes, for other machines please adjust the n_gpus_per_node config accordingly
python3 -m verl.trainer.main_ppo --config-path=config \
    --config-name='ppo_megatron_trainer.yaml'\
    algorithm.adv_estimator=gae \
    data.train_files="$train_files" \
    data.val_files="$test_files" \
    data.train_batch_size=1024 \
    data.max_prompt_length=1024 \
    data.max_response_length=512 \
    data.filter_overlong_prompts=True \
    data.truncation='error' \
    actor_rollout_ref.model.path=Qwen/Qwen2-7B-Instruct \
    actor_rollout_ref.actor.optim.lr=1e-6 \
    actor_rollout_ref.actor.ppo_mini_batch_size=256 \
    actor_rollout_ref.actor.ppo_micro_batch_size_per_gpu=4 \
    actor_rollout_ref.actor.megatron.pipeline_model_parallel_size=2 \
    actor_rollout_ref.actor.megatron.virtual_pipeline_model_parallel_size=2 \
    actor_rollout_ref.actor.megatron.tensor_model_parallel_size=4 \
    actor_rollout_ref.actor.use_kl_loss=False \
    actor_rollout_ref.model.enable_gradient_checkpointing=True \
    actor_rollout_ref.rollout.log_prob_micro_batch_size_per_gpu=16 \
    actor_rollout_ref.rollout.tensor_model_parallel_size=4 \
    actor_rollout_ref.rollout.name=vllm \
    actor_rollout_ref.rollout.gpu_memory_utilization=0.6 \
    actor_rollout_ref.ref.log_prob_micro_batch_size_per_gpu=16 \
    actor_rollout_ref.ref.megatron.pipeline_model_parallel_size=2 \
    actor_rollout_ref.ref.megatron.virtual_pipeline_model_parallel_size=2 \
    actor_rollout_ref.ref.megatron.tensor_model_parallel_size=4 \
    critic.optim.lr=1e-5 \
    critic.model.path=Qwen/Qwen2-7B-Instruct \
    critic.model.enable_gradient_checkpointing=True \
    critic.ppo_micro_batch_size_per_gpu=4 \
    critic.megatron.pipeline_model_parallel_size=2 \
    critic.megatron.virtual_pipeline_model_parallel_size=2 \
    critic.megatron.tensor_model_parallel_size=4 \
    algorithm.use_kl_in_reward=True \
    algorithm.kl_penalty=kl \
    algorithm.kl_ctrl.kl_coef=0.001 \
    trainer.critic_warmup=0 \
    trainer.logger=['console','wandb'] \
    trainer.project_name='verl_megatron_gsm8k_examples' \
    trainer.experiment_name='Qwen2-7B-Instruct_function_rm_megatron' \
    trainer.n_gpus_per_node=16 \
    trainer.nnodes=1 \
    trainer.save_freq=-1 \
    trainer.test_freq=10 \
    trainer.total_epochs=15 $@
