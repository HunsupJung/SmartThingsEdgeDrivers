-- Copyright 2022 SmartThings
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Mock out globals
local test = require "integration_test"
local zigbee_test_utils = require "integration_test.zigbee_test_utils"
local clusters = require "st.zigbee.zcl.clusters"
local capabilities = require "st.capabilities"
local t_utils = require "integration_test.utils"

local WindowCovering = clusters.WindowCovering

local mock_device = test.mock_device.build_test_zigbee_device(
  { profile = t_utils.get_profile_definition("window-treatment-battery.yml"),
    fingerprinted_endpoint_id = 0x01,
    zigbee_endpoints = {
      [1] = {
        id = 1,
        manufacturer = "Yookee",
        model = "D10110",
        server_clusters = {0x000, 0x0001, 0x0003, 0x0004, 0x0005, 0x0102}
      }
    }
  }
)

zigbee_test_utils.prepare_zigbee_env_info()
local function test_init()
  test.mock_device.add_test_device(mock_device)
  zigbee_test_utils.init_noop_health_check_timer()
end

test.set_test_init_function(test_init)

test.register_coroutine_test(
  "State transition from opening to partially open",
  function()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")
    test.socket.zigbee:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 1)
      }
    )
    test.socket.capability:__expect_send(
        {
          mock_device.id,
          {
            capability_id = "windowShadeLevel", component_id = "main",
            attribute_id = "shadeLevel", state = { value = 99 }
          }
        }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.opening())
    )
    test.mock_time.advance_time(2)
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.partially_open())
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "State transition from opening to closing",
  function()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")
    test.socket.zigbee:__queue_receive(
      {
        mock_device.id,
        WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 10)
      }
    )
    test.socket.capability:__expect_send(
        {
          mock_device.id,
          {
            capability_id = "windowShadeLevel", component_id = "main",
            attribute_id = "shadeLevel", state = { value = 90 }
          }
        }
    )
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.opening())
    )
    test.mock_time.advance_time(2)
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.partially_open())
    )
    test.wait_for_events()
    test.timer.__create_and_queue_test_time_advance_timer(1, "oneshot")
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 15)
    })
    test.socket.capability:__expect_send({
      mock_device.id,
      {
        capability_id = "windowShadeLevel", component_id = "main",
        attribute_id = "shadeLevel", state = { value = 85 }
      }
    })
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.closing())
    )
    test.mock_time.advance_time(3)
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.partially_open())
    )
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "windowShadePreset capability should be handled",
  function()
    test.socket.device_lifecycle():__queue_receive(mock_device:generate_info_changed({preferences = {presetPosition = 30}}))
    test.wait_for_events()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        { capability = "windowShadePreset", component = "main", command = "presetPosition", args = {} }
      }
    )
    test.socket.zigbee:__expect_send({
      mock_device.id,
      WindowCovering.server.commands.GoToLiftPercentage(mock_device, 70)
    })
  end
)

test.register_coroutine_test(
  "windowShade Open command should be handled",
  function()
    test.socket.device_lifecycle():__queue_receive(mock_device:generate_info_changed({preferences = {presetPosition = 30}}))
    test.wait_for_events()
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        { capability = "windowShade", component = "main", command = "open", args = {} }
      }
    )
    test.socket.zigbee:__expect_send({
      mock_device.id,
      WindowCovering.server.commands.GoToLiftPercentage(mock_device, 0)
    })
  end
)

test.register_coroutine_test(
  "an attribute read should be sent after 30s of no response",
  function ()
    test.timer.__create_and_queue_test_time_advance_timer(30, "oneshot")
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        { capability = "windowShade", component = "main", command = "open", args = {} }
      }
    )
    test.socket.zigbee:__expect_send({
      mock_device.id,
      WindowCovering.server.commands.GoToLiftPercentage(mock_device, 0)
    })
    test.wait_for_events()
    test.mock_time.advance_time(30)
    test.socket.zigbee:__expect_send({
      mock_device.id,
      zigbee_test_utils.build_bind_request(mock_device,
                                            zigbee_test_utils.mock_hub_eui,
                                            clusters.WindowCovering.ID)
    })
    test.socket.zigbee:__expect_send({
      mock_device.id,
      clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:configure_reporting(mock_device,
                                                                                          0,
                                                                                          600,
                                                                                          1)
    })
    test.socket.zigbee:__expect_send({
      mock_device.id,
      clusters.WindowCovering.attributes.CurrentPositionLiftPercentage:read(mock_device)
    })
  end
)

test.register_coroutine_test(
  "an attribute read should not be sent after 30s if there is a response",
  function ()
    test.timer.__create_and_queue_test_time_advance_timer(30, "oneshot") --Only one timer in the driver
    test.timer.__create_and_queue_test_time_advance_timer(2, "oneshot") --delay timer for defaults parially open delay
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        { capability = "windowShade", component = "main", command = "open", args = {} }
      }
    )
    test.socket.zigbee:__expect_send({
      mock_device.id,
      WindowCovering.server.commands.GoToLiftPercentage(mock_device, 0)
    })
    test.wait_for_events()

    test.socket.zigbee:__queue_receive({
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 15)
    })
    test.socket.capability:__expect_send({
      mock_device.id,
      {
        capability_id = "windowShadeLevel", component_id = "main",
        attribute_id = "shadeLevel", state = { value = 85 }
      }
    })
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.opening())
    )
    test.wait_for_events()

    test.mock_time.advance_time(20)
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.partially_open())
    )
    test.wait_for_events()

    test.mock_time.advance_time(11)
    test.wait_for_events()
  end
)

test.register_coroutine_test(
  "an attribute read should not be sent after 30s if there is a response another timing",
  function ()
    test.timer.__create_and_queue_test_time_advance_timer(30, "oneshot") --Only one timer in the driver
    test.timer.__create_and_queue_test_time_advance_timer(2, "oneshot") --delay timer for defaults parially open delay
    test.socket.capability:__queue_receive(
      {
        mock_device.id,
        { capability = "windowShade", component = "main", command = "open", args = {} }
      }
    )
    test.socket.zigbee:__expect_send({
      mock_device.id,
      WindowCovering.server.commands.GoToLiftPercentage(mock_device, 0)
    })
    test.wait_for_events()

    test.mock_time.advance_time(1)
    test.socket.zigbee:__queue_receive({
      mock_device.id,
      WindowCovering.attributes.CurrentPositionLiftPercentage:build_test_attr_report(mock_device, 15)
    })
    test.socket.capability:__expect_send({
      mock_device.id,
      {
        capability_id = "windowShadeLevel", component_id = "main",
        attribute_id = "shadeLevel", state = { value = 85 }
      }
    })
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.opening())
    )
    test.wait_for_events()

    test.mock_time.advance_time(1)
    test.socket.capability:__expect_send(
      mock_device:generate_test_message("main", capabilities.windowShade.windowShade.partially_open())
    )
    test.wait_for_events()

    test.mock_time.advance_time(28)
    test.wait_for_events()
  end
)

test.run_registered_tests()
